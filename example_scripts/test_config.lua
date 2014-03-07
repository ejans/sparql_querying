#!/usr/bin/env luajit

local ffi = require("ffi")
local ubx = require "ubx"
local ts = tostring

-- prog starts here.
ni=ubx.node_create("test_config")

-- load modules
ubx.load_module(ni, "std_types/stdtypes/stdtypes.so")
ubx.load_module(ni, "std_blocks/webif/webif.so")
ubx.load_module(ni, "std_blocks/sparql_querying/sparql_queryer.so")
ubx.load_module(ni, "std_blocks/lfds_buffers/lfds_cyclic.so")
ubx.load_module(ni, "std_blocks/ptrig/ptrig.so")

ubx.ffi_load_types(ni)

-- create necessary blocks
print("creating instance of 'webif/webif'")
webif1=ubx.block_create(ni, "webif/webif", "webif1", { port="8888" })

print("creating instance of 'sparql_querying/sparql_queryer'")

sparql_conf=[[
   { query="PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT ?nick, ?name WHERE { ?x rdf:type foaf:Person . ?x foaf:nick ?nick . ?x foaf:name ?name}", datatype="xsd:string", uri="http://www.dajobe.org/foaf.rdf"}
]]

sparql_queryer1=ubx.block_create(ni, "sparql_querying/sparql_queryer", "sparql_queryer1",
                           {sparql_querying_conf=sparql_conf})

print("creating instance of 'std_triggers/ptrig'")
ptrig1=ubx.block_create(ni, "std_triggers/ptrig", "ptrig1", {
                period = {sec=2, usec=0},
		--sched_policy="SCHED_FIFO", sched_priority=85,
		sched_policy="SCHED_OTHER", sched_priority=0,
		trig_blocks={{ b=sparql_queryer1, num_steps=1, measure=0} 
                } } )

print("running webif init", ubx.block_init(webif1))
print("running ptrig1 init", ubx.block_init(ptrig1))
print("running sparql_queryer1 init", ubx.block_init(sparql_queryer1))

print("running webif start", ubx.block_start(webif1))

io.read()

node_cleanup(ni)
