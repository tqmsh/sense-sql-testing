"""Shared utilities for SQL extraction generators."""
import sqlparse


def normalize_sql(sql: str) -> str:
    """
    Normalize SQL formatting using sqlparse.
    - Expands single-line queries onto multiple lines (SELECT, FROM, JOIN, WHERE, etc.)
    - Collapses artificially bloated whitespace/blank lines
    - Uppercases keywords
    - Does NOT alter any identifiers, values, or query semantics
    """
    return sqlparse.format(
        sql,
        reindent=True,
        keyword_case="upper",
        strip_whitespace=True,
    ).strip()


def count_loc(sql: str) -> int:
    """Count non-blank lines in a SQL string."""
    return len([l for l in sql.splitlines() if l.strip()])
