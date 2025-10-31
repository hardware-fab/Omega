# Copyright (c) 2011-2023 Columbia University, System Level Design Group
# SPDX-License-Identifier: Apache-2.0

# User-defined configuration ports
# <<--directives-param-->>
set_directive_interface -mode ap_none "top" conf_info_motion_mvfs
set_directive_interface -mode ap_none "top" conf_info_motion_rdbfr
set_directive_interface -mode ap_none "top" conf_info_motion_n
set_directive_interface -mode ap_none "top" conf_info_motion_pwm

# Insert here any custom directive
set_directive_dataflow "top/go"
