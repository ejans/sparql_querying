--
-- Microblx sparql queryer
--
-- SPDX-License-Identifier: BSD-3-Clause LGPL-2.1+ 
--
--
local ubx=require("ubx")
local utils = require("utils")
local cdata = require("cdata")
local ffi = require("ffi")
local time = require("time")
local ts = tostring
local redland = require("redland")

-- color handling via ubx
red=ubx.red; blue=ubx.blue; cyan=ubx.cyan; white=ubx.cyan; green=ubx.green; yellow=ubx.yellow; magenta=ubx.magenta

-- global state
conf=nil

--- configuration example
--sample_conf=[[
--{ query="PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT ?nick, ?name WHERE { ?x rdf:type foaf:Person . ?x foaf:nick ?nick . ?x foaf:name ?name}", datatype="xsd:string", uri="http://www.dajobe.org/foaf.rdf"}
--]]

--- convert the conf string to a table
-- @param conf str
-- @param ni node_info
-- @return conf table
local function conf_to_conflist(c, this)
   local ni = this.ni
   local succ, res = utils.eval_sandbox("return "..c)
   if not succ then error(red("queryer: failed to load querying_conf:\n"..res, true)) end

   --for i,conf in ipairs(res) do
   return res
end

--- init: parse config and create port and connections.
function init(b)
   b=ffi.cast("ubx_block_t*", b)
   ubx.ffi_load_types(b.ni)

   --- get conf
   local conf_str = ubx.data_tolua(ubx.config_get_data(b, "querying_conf"))

   if conf_str == 0 then
      print(ubx.stafe_tostr(b.name)..": invalid/nonexisting querying_conf")
      return false
   end

   conf = conf_to_conflist(conf_str, b)
   u_data=ubx.data_alloc(b.ni, "struct queryer_data", 1)

   --- Redland part
   conf.world = redland.librdf_new_world()
   local storage = redland.librdf_new_storage(conf.world,'hashes','dummy',"new=yes,hash-type='memory'")
   conf.model = redland.librdf_new_model(conf.world,storage,'')
   --local parser = redland.librdf_new_parser(conf.world,'rdfxml','application/rdf+xml', null)
   local parser = redland.librdf_new_parser(conf.world,'rdfxml','application/rdf+xml', nil)
   local uri = redland.librdf_new_uri(conf.world,conf.uri)
   print("Parsing...")
   redland.librdf_parser_parse_into_model(parser,uri,uri,conf.model)
   print("Done")
   redland.librdf_free_uri(uri)
   redland.librdf_free_parser(parser)
   return true
end

--- start
function start(b)
   --print("Start")
   return true
end

--- step
function step(b)
   local query = redland.librdf_new_query(conf.world, 'sparql', nil, conf.query, nil)
   local results = redland.librdf_model_query_execute(conf.model, query)
   print("-----")
   --print(ts(results))
   local string_result = redland.librdf_query_results_to_string(results, nil, nil)
   print(string_result)
   print("-----")
   local char_result = ffi.cast("char *", string_result)
   print(char_result)

   --- Test to stdout
   --[[
   local count=0
   local val=0
   local nval=0
   while not(results == nil) and redland.librdf_query_results_finished(results) == 0 do
      print("result "..count..": {")
      for i = 0, redland.librdf_query_results_get_bindings_count(results) - 1, 1 do
         local val = redland.librdf_query_results_get_binding_value(results, i)
         if val then
            nval = redland.librdf_node_to_string(val)
         else
            nval = "(unbound)"
         end
         print(" "..redland.librdf_query_results_get_binding_name(results, i).."="..(nval or "(nil)"))
      end
      print("}")
      redland.librdf_query_results_next(results)
      count = count + 1
   end
   if not(results == nil) then
      print("Returned "..count.." results")
   end
   ]]--

   --- TODO send out
   local p = ubx.port_get(b, "result")
   local data = ffi.new("struct queryer_data")
   --- TODO Test
   print(data)
   data.result = char_result
   ubx.data_set(u_data, data)
   ubx.port_write(p, u_data)
end

--- cleanup
function cleanup(b)
   print("Cleanup")
   conf=nil
end
