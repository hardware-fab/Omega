# Copyright (c) 2011-2023 Columbia University, System Level Design Group
# SPDX-License-Identifier: Apache-2.0

# User-defined configuration ports
# <<--directives-param-->>
set_directive_interface -mode ap_none "top" conf_info_sha_vsize
set_directive_interface -mode ap_none "top" conf_info_sha_blocksize
set_directive_interface -mode ap_none "top" conf_info_sha_digest
set_directive_interface -mode ap_none "top" conf_info_sha_n

# Insert here any custom directive
set_directive_dataflow "top/go"
