"""Exercise the real backend view using in-memory Firestore and Django responses.

Never import production settings or firebase_admin; no credentials are needed.
"""
import argparse
import copy
import importlib.util
import json
from pathlib import Path
import sys
import types
import unittest
from unittest.mock import patch

from django.conf import settings
from django.test import RequestFactory


class Document:
    def __init__(self, document_id, data):
        self.id = document_id
        self.data = data

    def get(self, key):
        return self.data.get(key)

    def to_dict(self):
        return copy.deepcopy(self.data)


class Collection:
    def __init__(self, documents):
        self.documents = documents

    def stream(self):
        return iter(self.documents)

    def where(self, field, operator, value):
        if operator != '==':
            raise AssertionError('Unsupported fake query: ' + operator)
        return Collection([doc for doc in self.documents if doc.get(field) == value])


class Database:
    def __init__(self):
        self.collections = {
            'brands': [Document('1', {'id': 1, 'name': 'Toyota'})],
            'models': [Document('2', {'id': 2, 'brandId': 1, 'name': 'Camry'})],
            'cars': [Document('3', {'id': 3, 'modelId': 2, 'location': 'Hà Nội', 'price': 123.5})],
            'posts': [Document('4', {'id': 4, 'carId': 3, 'userId': 'seller-1',
                                    'title': 'Family sedan', 'description': 'Well maintained'})],
            'users': [Document('seller-1', {'name': 'Test Seller', 'phone': '0900000000', 'address': 'Test address'})],
            'images': [Document('5', {'carId': 3, 'url': 'https://example.invalid/car.jpg'}),
                       Document('6', {'carId': 999, 'url': 'https://example.invalid/other.jpg'})],
        }

    def collection(self, name):
        return Collection(self.collections[name])


class SearchContractTests(unittest.TestCase):
    view_module = None

    def setUp(self):
        self.database = Database()
        self.view_module.db = self.database
        self.requests = RequestFactory()

    def search(self, query=None):
        request = self.requests.get('/onlinecar/search-posts/', {} if query is None else {'query': query})
        response = self.view_module.search_posts_fuzzy(request)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response['Content-Type'], 'application/json')
        return json.loads(response.content)

    def test_empty_query_returns_joined_contract(self):
        rows = self.search()
        self.assertEqual(len(rows), 1)
        row = rows[0]
        self.assertEqual(set(row), {'post', 'car', 'carModel', 'brand', 'imageUrls',
                                    'sellerName', 'sellerPhone', 'sellerAddress', 'carLocation'})
        self.assertEqual(row['post']['id'], 4)
        self.assertEqual(row['car']['price'], 123.5)
        self.assertEqual(row['brand']['name'], 'Toyota')
        self.assertEqual(row['carModel']['name'], 'Camry')
        self.assertEqual(row['sellerPhone'], '0900000000')
        self.assertEqual(row['sellerAddress'], 'Test address')
        self.assertEqual(row['imageUrls'], ['https://example.invalid/car.jpg'])

    def test_search_fields_and_case_normalization(self):
        for query in [' TOYOTA ', 'camry', 'FAMILY', 'maintained', 'hà nội', 'test seller']:
            with self.subTest(query=query):
                self.assertEqual(len(self.search(query)), 1)

    def test_non_matching_query_returns_empty_list(self):
        self.assertEqual(self.search('not-a-match'), [])

    def test_whitespace_query_returns_all(self):
        self.assertEqual(len(self.search('   ')), 1)

    def test_missing_car_skips_orphan_post(self):
        self.database.collections['cars'] = []
        self.assertEqual(self.search(), [])

    def test_missing_user_preserves_listing_with_null_seller(self):
        self.database.collections['users'] = []
        row = self.search()[0]
        for field in ['sellerName', 'sellerPhone', 'sellerAddress']:
            self.assertIsNone(row[field])

    def test_null_user_id_preserves_listing(self):
        self.database.collections['posts'][0].data['userId'] = None
        self.assertIsNone(self.search()[0]['sellerName'])

    def test_missing_model_and_brand_preserves_title_search(self):
        self.database.collections['models'] = []
        row = self.search('sedan')[0]
        self.assertIsNone(row['carModel'])
        self.assertIsNone(row['brand'])

    def test_no_images_returns_empty_array(self):
        self.database.collections['images'] = []
        self.assertEqual(self.search()[0]['imageUrls'], [])

    def test_empty_database_returns_empty_array(self):
        for name in self.database.collections:
            self.database.collections[name] = []
        self.assertEqual(self.search(), [])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--backend', required=True, type=Path)
    args = parser.parse_args()
    view_path = args.backend / 'onlinecar' / 'views.py'
    if not view_path.is_file():
        parser.error('Backend onlinecar/views.py not found: ' + str(view_path))
    if not settings.configured:
        settings.configure(DEFAULT_CHARSET='utf-8', SECRET_KEY='local-unit-tests-only', USE_TZ=True)
    # Load the real view file without importing backend settings or its service account.
    fake_admin = types.ModuleType('firebase_admin')
    fake_firestore = types.ModuleType('firebase_admin.firestore')
    fake_firestore.client = lambda: Database()
    fake_admin.firestore = fake_firestore
    spec = importlib.util.spec_from_file_location('backend_view_under_test', view_path)
    module = importlib.util.module_from_spec(spec)
    with patch.dict(sys.modules, {'firebase_admin': fake_admin, 'firebase_admin.firestore': fake_firestore}):
        with patch('socket.socket.connect', side_effect=AssertionError('Network forbidden in isolated backend tests')):
            spec.loader.exec_module(module)
            SearchContractTests.view_module = module
            result = unittest.TextTestRunner(verbosity=2).run(
                unittest.defaultTestLoader.loadTestsFromTestCase(SearchContractTests))
    return 0 if result.wasSuccessful() else 1


if __name__ == '__main__':
    sys.exit(main())
