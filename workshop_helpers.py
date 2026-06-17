"""Shared visualization helpers for the AGA workshop notebooks.

After creating your GDS session, call ``configure(...)`` once, then use
``visualize_query(cypher)`` and ``visualize_projection(G)`` anywhere in the notebook.

These wrap the Neo4j driver and neo4j-viz so the lesson cells stay focused on
GDS / Aura Graph Analytics rather than visualization plumbing.
"""

from neo4j import GraphDatabase, RoutingControl, Result
from neo4j_viz.neo4j import from_neo4j
from neo4j_viz.gds import from_gds

# Connection / session context, populated by configure().
_ctx = {
    "gds": None,
    "uri": None,
    "username": None,
    "password": None,
    "database": "neo4j",
    "max_node_count": 20,
    "max_relationship_count": None,
}


def configure(gds, uri, username, password, database="neo4j",
              max_node_count=20, max_relationship_count=None):
    """Store the session and connection details the helpers need.

    Call this once, right after you create your GDS session.
    """
    _ctx.update(
        gds=gds, uri=uri, username=username, password=password,
        database=database, max_node_count=max_node_count,
        max_relationship_count=max_relationship_count,
    )


def execute_neo4j_query(query, params=None, database=None):
    """Run a Cypher query with the Neo4j driver, returning a graph result for visualization."""
    with GraphDatabase.driver(_ctx["uri"], auth=(_ctx["username"], _ctx["password"])) as driver:
        driver.verify_connectivity()
        return driver.execute_query(
            query,
            parameters_=params or {},
            database_=database or _ctx["database"],
            routing_=RoutingControl.READ,
            result_transformer_=Result.graph,
        )


def visualize_query(query, params=None, color_field=None, database=None):
    """Build a neo4j-viz visualization from a Cypher query."""
    VG = from_neo4j(execute_neo4j_query(query, params, database))
    if color_field:
        VG.color_nodes(field=color_field)
    return VG


def visualize_projection(G, max_node_count=None, max_relationship_count=None):
    """Visualize a projected GDS graph."""
    mnc = _ctx["max_node_count"] if max_node_count is None else max_node_count
    mrc = _ctx["max_relationship_count"] if max_relationship_count is None else max_relationship_count
    kwargs = {"max_node_count": mnc}
    if mrc is not None:
        kwargs["max_relationship_count"] = mrc
    return from_gds(_ctx["gds"], G, **kwargs)
