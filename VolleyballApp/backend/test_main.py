import unittest
import os
from config import get_allowed_origins

class TestCORSLogic(unittest.TestCase):
    def setUp(self):
        # Store original environment variable
        self.original_origins = os.environ.get("ALLOWED_ORIGINS")

    def tearDown(self):
        # Restore original environment variable
        if self.original_origins is None:
            if "ALLOWED_ORIGINS" in os.environ:
                del os.environ["ALLOWED_ORIGINS"]
        else:
            os.environ["ALLOWED_ORIGINS"] = self.original_origins

    def test_default_origins(self):
        if "ALLOWED_ORIGINS" in os.environ:
            del os.environ["ALLOWED_ORIGINS"]
        origins = get_allowed_origins()
        expected = ["http://localhost:8001", "http://127.0.0.1:8001", "http://localhost:8000", "http://127.0.0.1:8000"]
        self.assertEqual(origins, expected)

    def test_env_origins(self):
        os.environ["ALLOWED_ORIGINS"] = "http://myapp.com, http://another.com"
        origins = get_allowed_origins()
        expected = ["http://myapp.com", "http://another.com"]
        self.assertEqual(origins, expected)

    def test_env_origins_single(self):
        os.environ["ALLOWED_ORIGINS"] = "http://onlyone.com"
        origins = get_allowed_origins()
        expected = ["http://onlyone.com"]
        self.assertEqual(origins, expected)

    def test_empty_env(self):
        os.environ["ALLOWED_ORIGINS"] = ""
        origins = get_allowed_origins()
        self.assertEqual(origins, [])

if __name__ == "__main__":
    unittest.main()
