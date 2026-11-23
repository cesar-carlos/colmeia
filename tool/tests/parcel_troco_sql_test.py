"""Execute the production CASE in SQLite, independently of bridge availability.

This validates arithmetic, not SQL Anywhere joins, policies or query plans.
"""

from pathlib import Path
import re
import sqlite3
import unittest


class ParcelTrocoSqlTest(unittest.TestCase):
    def setUp(self):
        root = Path(__file__).resolve().parents[2]
        source = (root / "lib/features/agent_queries/data/queries/"
                  "parcela_produto_vendido_detalhe_sql.dart").read_text(
                      encoding="utf-8")
        self.expression = re.search(
            r"trocoExpression = '''(.*?)'''", source, re.S).group(1)
        self.db = sqlite3.connect(":memory:")
        self.addCleanup(self.db.close)

    def allocate(self, method, parcel, total, eligible, change):
        return self.db.execute(
            "SELECT " + self.expression + " FROM (SELECT ? TipoForma, "
            "? ValorParcela, ? ValorTotalParcelas, "
            "? ValorTotalParcelasRateioTroco, ? ValorTotalTrocoVenda) det",
            (method, parcel, total, eligible, change),
        ).fetchone()[0]

    def test_mixed_payment_deducts_change_only_once(self):
        cash = self.allocate("DH", 100.0, 150.0, 100.0, 20.0)
        card = self.allocate("CC", 50.0, 150.0, 100.0, 20.0)
        self.assertAlmostEqual(cash, 20.0)
        self.assertAlmostEqual(card, 0.0)
        self.assertAlmostEqual(150.0 - cash - card, 130.0)

    def test_insufficient_eligible_payments_use_all_parcels(self):
        cash = self.allocate("DH", 10.0, 100.0, 10.0, 20.0)
        card = self.allocate("CC", 90.0, 100.0, 10.0, 20.0)
        self.assertAlmostEqual(cash, 2.0)
        self.assertAlmostEqual(card, 18.0)
        self.assertAlmostEqual(cash + card, 20.0)

    def test_each_eligible_method_uses_proportional_allocation(self):
        for method in ("DH", "CH", "VL", "PX", "PIX"):
            with self.subTest(method=method):
                self.assertAlmostEqual(
                    self.allocate(method, 50.0, 150.0, 100.0, 20.0), 10.0)

    def test_no_change_including_zero_total(self):
        for total in (0.0, 100.0):
            with self.subTest(total=total):
                self.assertEqual(
                    self.allocate("DH", total, total, total, 0.0), 0.0)

    def test_no_eligible_payment_uses_total(self):
        self.assertAlmostEqual(
            self.allocate("CC", 50.0, 100.0, 0.0, 20.0), 10.0)


if __name__ == "__main__":
    unittest.main()
