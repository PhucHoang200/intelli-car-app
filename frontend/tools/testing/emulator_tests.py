"""Real Firestore emulator + backend search; refuses non-loopback/live projects."""
import importlib.util
import json
import os
from pathlib import Path
import sys
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from django.conf import settings
from django.test import RequestFactory
import firebase_admin
from firebase_admin import firestore
from firebase_admin import credentials
from google.auth.credentials import AnonymousCredentials
from backend_tests import Database

PROJECT = 'demo-intelli-car-tests'


class EmulatorCredential(credentials.Base):
    def get_credential(self):
        return AnonymousCredentials()


class FirestoreIntegrationTests(unittest.TestCase):
    db = None
    view = None

    @classmethod
    def setUpClass(cls):
        # This project's emulator instance is dedicated to this script.
        cls.seeded = []
        for collection, documents in Database().collections.items():
            for document in documents:
                reference = cls.db.collection(collection).document(document.id)
                reference.set(document.to_dict())
                cls.seeded.append(reference)

    @classmethod
    def tearDownClass(cls):
        for reference in cls.seeded:
            reference.delete()

    def test_search_joins_real_emulator_documents(self):
        response = self.view.search_posts_fuzzy(RequestFactory().get('/onlinecar/search-posts/', {'query': 'TOYOTA'}))
        self.assertEqual(response.status_code, 200)
        rows = json.loads(response.content)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['post']['id'], 4)
        self.assertEqual(rows[0]['sellerName'], 'Test Seller')
        self.assertEqual(rows[0]['imageUrls'], ['https://example.invalid/car.jpg'])

    def test_search_no_match(self):
        response = self.view.search_posts_fuzzy(RequestFactory().get('/onlinecar/search-posts/', {'query': 'absent'}))
        self.assertEqual(json.loads(response.content), [])

    def test_test_rules_reject_unauthenticated_read(self):
        url = ('http://' + os.environ['FIRESTORE_EMULATOR_HOST'] +
               '/v1/projects/' + PROJECT + '/databases/(default)/documents/posts/4')
        with self.assertRaises(HTTPError) as caught:
            urlopen(Request(url), timeout=10)
        self.assertEqual(caught.exception.code, 403)


def main():
    host = os.environ.get('FIRESTORE_EMULATOR_HOST', '')
    if host not in ('127.0.0.1:8088', 'localhost:8088'):
        raise RuntimeError('Run via --firebase; requires loopback Firestore emulator on port 8088')
    if os.environ.get('GCLOUD_PROJECT') != PROJECT:
        raise RuntimeError('Only demo-intelli-car-tests is permitted')
    view_path = Path(os.environ['TEST_BACKEND_PATH']) / 'onlinecar' / 'views.py'
    if not settings.configured:
        settings.configure(DEFAULT_CHARSET='utf-8', SECRET_KEY='emulator-tests-only', USE_TZ=True)
    # Explicit anonymous credentials prevent Admin SDK from loading ADC/service accounts.
    firebase_admin.initialize_app(EmulatorCredential(), options={'projectId': PROJECT})
    db = firestore.client()
    spec = importlib.util.spec_from_file_location('emulator_backend_view', view_path)
    view = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(view)
    FirestoreIntegrationTests.db = db
    FirestoreIntegrationTests.view = view
    result = unittest.TextTestRunner(verbosity=2).run(
        unittest.defaultTestLoader.loadTestsFromTestCase(FirestoreIntegrationTests))
    return int(not result.wasSuccessful())


if __name__ == '__main__':
    sys.exit(main())
