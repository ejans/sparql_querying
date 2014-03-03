#!/usr/bin/luajit

local ubx=require("ubx")
local ubx_utils = require("ubx_utils")
local utils = require("utils")
local cdata = require("cdata")
local ffi = require("ffi")
local time = require("time")
local ts = tostring
local strict = require"strict"

-- global state
conf=nil

--- configuration example
--sample_conf=[[
--{ query="PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT ?nick, ?name WHERE { ?x rdf:type foaf:Person . ?x foaf:nick ?nick . ?x foaf:name ?name}", datatype="xsd:string"}
--]]

--- convert the conf string to a table
-- @param conf str
-- @param ni node_info
-- @return conf table
local function conf_to_conflist(c, this)
   local ni = this.ni
   local succ, res = utils.eval_sandbox("return "..c)
   if not succ then error("sparql_queryer: failed to load sparql_querying_conf:\n"..res) end

   --for i,conf in ipairs(res) do
   return res
end

--- init: parse config and create port and connections.
function init(b)
   b=ffi.cast("ubx_block_t*", b)
   ubx.ffi_load_types(b.ni)

   --- get conf
   local conf_str = ubx.data_tolua(ubx.config_get_data(b, "sparql_querying_conf"))

   if conf_str == 0 then
      print(ubx.stafe_tostr(b.name)..": invalid/nonexisting sparql_querying_conf")
      return false
   end

   conf = conf_to_conflist(conf_str, b)
   --- TODO Test
   print("###")
   print(conf)
   print("###")
   return true
end

--- start
function start(b)
   
   return true
end

--- step
function step(b)
   
end

--- cleanup
function cleanup(b)
   conf=nil
end
