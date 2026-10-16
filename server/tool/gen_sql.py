"""Generate server/lib/repository/sql/*_sql.dart from docs/spec/database/queries.sql.

Run from the repository root: python3 server/tool/gen_sql.py "$PWD"
"""
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
src = (root / "docs/spec/database/queries.sql").read_text(encoding="utf-8")

REPOS = {
    "insured_person": ("InsuredPersonSql", "InsuredPersonRepository", ["Q1.1", "Q1.2", "Q1.3", "Q1.4", "Q1.5"]),
    "claim": ("ClaimSql", "ClaimRepository", ["Q1.6", "Q1.7", "Q1.8", "Q1.9", "Q1.10", "Q2.4", "QO1.1", "QO1.2", "QO1.3",
                                              "QO1.4", "QO1.5", "QO1.6", "QO2.1", "QO3.1", "QO3.2", "QO5.4"]),
    "notification": ("NotificationSql", "NotificationRepository", ["Q2.1", "Q2.2", "Q2.3", "Q3.1", "Q3.7",
                                                                   "QN.1", "QN.2", "QN.3", "QN.4", "QN.5"]),
    "appointment": ("AppointmentSql", "AppointmentRepository", ["Q3.2", "Q3.3", "Q3.4", "Q3.5", "Q3.6", "QU5.1",
                                                                "QO4.1", "QO4.2", "QO4.3", "QC1.1"]),
    "treatment": ("TreatmentSql", "TreatmentRepository", ["QU4.1", "QU4.2", "QU4.3", "Q6.1", "QO5.1", "QO5.2",
                                                          "QO5.3"]),
    "report": ("ReportSql", "ReportRepository", ["QO6.1", "QO6.2", "QO6.3", "QC2.1", "QC2.2", "QC2.3", "QC2.4",
                                                 "QC2.5", "QC2.6", "QC2.7"]),
}

header_re = re.compile(r"^-- (Q[A-Z]*\d*\.\d+)\s+\[([^\]]+)\]\s+(.*)$")
sql_start = re.compile(r"^\s*(SELECT|INSERT|UPDATE|WITH|DELETE)\b")

blocks = {}
order = []
cur = None
for line in src.splitlines():
    m = header_re.match(line)
    if m:
        cur = m.group(1)
        blocks[cur] = {"uc": m.group(2), "name": m.group(3), "lines": []}
        order.append(cur)
        continue
    if cur is not None:
        blocks[cur]["lines"].append(line)

def statements(lines):
    # Drop header continuation lines (Thai use case names without "--") before the first SQL line.
    i = 0
    while i < len(lines) and not sql_start.match(lines[i]):
        i += 1
    body = "\n".join(lines[i:])
    parts = []
    for chunk in re.split(r";[ \t]*\n", body + "\n"):
        text = "\n".join(l.rstrip() for l in chunk.strip("\n").splitlines()).strip()
        if text:
            parts.append(text)
    return parts

def ident(qid):
    return "q" + qid[1:].replace(".", "_")

assert len(order) == 58, len(order)
used = [q for _, _, qs in REPOS.values() for q in qs]
assert sorted(used) == sorted(order), set(order) ^ set(used)

out_dir = root / "server/lib/repository/sql"
out_dir.mkdir(parents=True, exist_ok=True)
for file, (cls, repo, qids) in REPOS.items():
    out = [
        "// GENERATED from docs/spec/database/queries.sql. Do not edit by hand.",
        "// The test queries_match_report_test.dart makes sure that this text stays the same as the report.",
        "// ignore_for_file: constant_identifier_names",
        "",
        f"/// SQL of [{repo}]. Each constant has the name of its Query ID.",
        f"abstract final class {cls} {{",
    ]
    for q in qids:
        b = blocks[q]
        stmts = statements(b["lines"])
        out.append(f"  // {q} [{b['uc']}] {b['name']}")
        if len(stmts) == 1:
            out.append(f"  static const {ident(q)} = r'''")
            out.append(stmts[0])
            out.append("''';")
        else:
            out.append(f"  static const {ident(q)} = <String>[")
            for s in stmts:
                out.append("    r'''")
                out.append(s)
                out.append("''',")
            out.append("  ];")
        out.append("")
    out.append("  /// Every Query ID of this class, for the test that compares the SQL with the report.")
    out.append("  static const all = <String, List<String>>{")
    for q in qids:
        n = len(statements(blocks[q]["lines"]))
        val = ident(q) if n > 1 else f"[{ident(q)}]"
        out.append(f"    '{q}': {val},")
    out.append("  };")
    out.append("}")
    (out_dir / f"{file}_sql.dart").write_text("\n".join(out) + "\n", encoding="utf-8")
    print(file, len(qids))
