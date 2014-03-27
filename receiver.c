/* #define DEBUG 1 */

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#include "ubx.h"
#include "types/queryer_data.h"
#include "types/queryer_data.h.hexarr"

ubx_type_t queryer_data_type = def_struct_type(struct queryer_data, &queryer_data_h);

char tmp_meta[] =
	"{ doc='A receiver test block',"
	"  real-time=true,"
	"}";

ubx_port_t tmp_ports[] = {
	{ .name="data", .in_type_name="struct queryer_data" },
	{ NULL },
};

def_read_fun(read_data, struct queryer_data)

static void tmp_step(ubx_block_t *b) {
	struct queryer_data dat;
	ubx_port_t* data_port = ubx_port_get(b, "data");
	read_data(data_port, &dat);
	printf("TEXT: %s\n", dat.result);
	//printf("NUMBER: %u\n", dat.number);
	printf("---------\n");
}

ubx_block_t template_comp = {
	.name = "sparql_querying/receiver",
	.type = BLOCK_TYPE_COMPUTATION,
	.meta_data = tmp_meta,
	.ports = tmp_ports,
	.step = tmp_step,
};

static int tmp_module_init(ubx_node_info_t* ni)
{
	ubx_type_register(ni, &queryer_data_type);
	return ubx_block_register(ni, &template_comp);
}

static void tmp_module_cleanup(ubx_node_info_t *ni)
{
	ubx_type_unregister(ni, "struct queryer_data");
	ubx_block_unregister(ni, "charsender/receiver");
}

UBX_MODULE_INIT(tmp_module_init)
UBX_MODULE_CLEANUP(tmp_module_cleanup)
UBX_MODULE_LICENSE_SPDX(BSD-3-Clause)
