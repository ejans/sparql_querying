/*
 * microblx: embedded, real-time safe, reflective function blocks.
 * Copyright (C) 2013,2014 Markus Klotzbuecher <markus.klotzbuecher@mech.kuleuven.be>
 *
 * microblx is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 or (at your option)
 * any later version.
 *
 * microblx is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with eCos; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * As a special exception, if other files instantiate templates or use
 * macros or inline functions from this file, or you compile this file
 * and link it with other works to produce a work based on this file,
 * this file does not by itself cause the resulting work to be covered
 * by the GNU General Public License. However the source code for this
 * file must still be made available in accordance with section (3) of
 * the GNU General Public License.
 *
 * This exception does not invalidate any other reasons why a work
 * based on this file might be covered by the GNU General Public
 * License.
*/

/*
 * A generic luajit based block.
 */

/* #define DEBUG	1 */
#define COMPILE_IN_LOG_LUA_FILE

#include <luajit-2.0/lauxlib.h>
#include <luajit-2.0/lualib.h>
#include <luajit-2.0/lua.h>

#include <stdio.h>
#include <stdlib.h>

#include "ubx.h"

#include "types/queryer_data.h"
#include "types/queryer_data.h.hexarr"

ubx_type_t queryer_data_type = def_struct_type(struct queryer_data, &queryer_data_h);

#ifdef COMPILE_IN_LOG_LUA_FILE
#include "queryer.lua.hexarr"
#else
#define FILE_LOG_FILE "/home/mk/prog/c/microblx/std_blocks/sparql_querying/queryer.lua"
#endif

char queryer_meta[] =
	"{ doc='A reporting block that writes to a queryer file',"
	"  license='MIT',"
	"  real-time=false,"
	"}";

ubx_config_t queryer_conf[] = {
	{ .name="querying_conf", .type_name="char" },
	{ .name="filename", .type_name="char" },
	{ .name="separator", .type_name="char"},
	{ .name="timestamp", .type_name="int"},
	{ NULL }
};

ubx_port_t queryer_ports[] = {
	//{ .name="query_command", .in_type_name="char*" },
	{ .name="query_command", .in_type_name="char" },
	{ .name="result", .out_type_name="struct queryer_data" },
	//{ .name="result", .out_type_name="char" },
	{ NULL },
};

struct queryer_info {
	struct lua_State* L;
};

//def_read_fun(read_char, char)
//def_write_fun(write_queryer_data, struct queryer_data)

/**
 * @brief: call a hook with fname.
 *
 * @param block (is passed on a first arg)
 * @param fname name of function to call
 * @param require_fun raise an error if function fname does not exist.
 * @param require_res if 1, require a boolean valued result.
 * @return -1 in case of error, 0 otherwise.
 */
int call_hook(ubx_block_t* b, const char *fname, int require_fun, int require_res)
{
	int ret = 0;
	struct queryer_info* inf = (struct queryer_info*) b->private_data;
	int num_res = (require_res != 0) ? 1 : 0;

	lua_getglobal(inf->L, fname);

	if(lua_isnil(inf->L, -1)) {
		lua_pop(inf->L, 1);
		if(require_fun)
			ERR("%s: no (required) Lua function %s", b->name, fname);
		goto out;
	}

	lua_pushlightuserdata(inf->L, (void*) b);

	if (lua_pcall(inf->L, 1, num_res, 0) != 0) {
		ERR("%s: error calling function %s: %s", b->name, fname, lua_tostring(inf->L, -1));
		lua_pop(inf->L, 1); /* pop result */
		ret = -1;
		goto out;
	}

	if(require_res) {
		if (!lua_isboolean(inf->L, -1)) {
			ERR("%s: %s must return a bool but returned a %s",
			    b->name, fname, lua_typename(inf->L, lua_type(inf->L, -1)));
			ret = -1;
			goto out;
		}
		ret = !(lua_toboolean(inf->L, -1)); /* back in C! */
		lua_pop(inf->L, 1); /* pop result */
	}
 out:
	return ret;
}

/**
 * init_lua_state - initalize lua_State and execute lua_file.
 *
 * @param inf
 * @param lua_file
 *
 * @return 0 if Ok, -1 otherwise.
 */
static int init_lua_state(struct queryer_info* inf)
{
	int ret=-1;

	if((inf->L=luaL_newstate())==NULL) {
		ERR("failed to alloc lua_State");
		goto out;
	}

	luaL_openlibs(inf->L);

#ifdef COMPILE_IN_LOG_LUA_FILE
	ret = luaL_dostring(inf->L, (const char*) &queryer_lua);
#else
	ret = luaL_dofile(inf->L, FILE_LOG_FILE);
#endif
	
	if (ret) {
		ERR("Failed to load queryer.lua: %s\n", lua_tostring(inf->L, -1));
		goto out;
	}
	ret=0;

 out:
	return ret;
}

static int queryer_init(ubx_block_t *b)
{
	DBG(" ");
	int ret = -EOUTOFMEM;
	struct queryer_info* inf;

	if((inf = calloc(1, sizeof(struct queryer_info)))==NULL)
		goto out;

	b->private_data = inf;

	if(init_lua_state(inf) != 0)
		goto out_free;

	if((ret=call_hook(b, "init", 0, 1)) != 0)
		goto out_free;

	/* Ok! */
	ret = 0;
	goto out;

 out_free:
	free(inf);
 out:
	return ret;
}

static int queryer_start(ubx_block_t *b)
{
	DBG(" ");
	return call_hook(b, "start", 0, 1);
}

/**
 * queryer_step - execute lua string and call step hook
 *
 * @param b
 */
static void queryer_step(ubx_block_t *b)
{
	call_hook(b, "step", 0, 0);
	return;
}

static void queryer_stop(ubx_block_t *b)
{
	call_hook(b, "stop", 0, 0);
}

static void queryer_cleanup(ubx_block_t *b)
{
	struct queryer_info* inf = (struct queryer_info*) b->private_data;
	call_hook(b, "cleanup", 0, 0);
	lua_close(inf->L);
	free(b->private_data);
}

/* put everything together */
ubx_block_t lua_comp = {
	.name = "sparql_querying/queryer",
	.type = BLOCK_TYPE_COMPUTATION,
	.meta_data = queryer_meta,
	.configs = queryer_conf,
	/* .ports = lua_ports, */
	.ports = queryer_ports,

	/* ops */
	.init = queryer_init,
	.start = queryer_start,
	.step = queryer_step,
	.stop = queryer_stop,
	.cleanup = queryer_cleanup,
};

static int queryer_mod_init(ubx_node_info_t* ni)
{
	ubx_type_register(ni, &queryer_data_type);
	return ubx_block_register(ni, &lua_comp);
}

static void queryer_mod_cleanup(ubx_node_info_t *ni)
{
	ubx_type_unregister(ni, "struct queryer_data");
	ubx_block_unregister(ni, "sparql_querying/queryer");
}

UBX_MODULE_INIT(queryer_mod_init)
UBX_MODULE_CLEANUP(queryer_mod_cleanup)
UBX_MODULE_LICENSE_SPDX(BSD-3-Clause LGPL-2.1+)
