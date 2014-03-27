#!/usr/bin/env luajit

local ffi = require("ffi")
local ubx = require "ubx"
local ts = tostring

-- prog starts here.
ni=ubx.node_create("test_config")

-- load modules
ubx.load_module(ni, "std_types/stdtypes/stdtypes.so")
ubx.load_module(ni, "std_blocks/webif/webif.so")
ubx.load_module(ni, "std_blocks/sparql_querying/queryer.so")
ubx.load_module(ni, "std_blocks/sparql_querying/receiver.so")
--ubx.load_module(ni, "std_blocks/sparql_querying/filter.so")
ubx.load_module(ni, "std_blocks/lfds_buffers/lfds_cyclic.so")
ubx.load_module(ni, "std_blocks/ptrig/ptrig.so")

ubx.ffi_load_types(ni)

-- create necessary blocks
print("creating instance of 'webif/webif'")
webif1=ubx.block_create(ni, "webif/webif", "webif1", { port="8888" })

print("creating instance of 'sparql_querying/queryer'")

sparql_conf=[[
   { query="PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT ?nick, ?name WHERE { ?x rdf:type foaf:Person . ?x foaf:nick ?nick . ?x foaf:name ?name}", datatype="xsd:string", uri="http://www.dajobe.org/foaf.rdf"}
]]

queryer1=ubx.block_create(ni, "sparql_querying/queryer", "queryer1",
                           {querying_conf=sparql_conf})

receiver1=ubx.block_create(ni, "sparql_querying/receiver", "receiver1")

fifo1=ubx.block_create(ni, "lfds_buffers/cyclic", "fifo1", {buffer_len=1, type_name="struct queryer_data"})

print("creating instance of 'std_triggers/ptrig'")
ptrig1=ubx.block_create(ni, "std_triggers/ptrig", "ptrig1", {
                period = {sec=2, usec=0},
		sched_policy="SCHED_OTHER", sched_priority=0,
		trig_blocks={{ b=queryer1, num_steps=1, measure=0},
		             { b=receiver1, num_steps=1, measure=0}
                } } )

queryer_port=ubx.port_get(queryer1, "result")
receiver_port=ubx.port_get(receiver1, "data")
ubx.port_connect_out(queryer_port, fifo1)
ubx.port_connect_in(receiver_port, fifo1)

print("running webif init", ubx.block_init(webif1))
print("running ptrig1 init", ubx.block_init(ptrig1))
print("running queryer1 init", ubx.block_init(queryer1))
print("running receiver1 init", ubx.block_init(receiver1))
print("running fifo1 init", ubx.block_init(fifo1))

print("running webif start", ubx.block_start(webif1))
print("running fifo start", ubx.block_start(fifo1))
print("running queryer start", ubx.block_start(queryer1))
print("running receiver start", ubx.block_start(receiver1))

print("start ptrig1 to run example")

io.read()

node_cleanup(ni)
