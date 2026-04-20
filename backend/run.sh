#!/bin/bash
export SUNO_CALLBACK_URL="https://punctuate-demote-rocking.ngrok-free.dev/api/suno/callback"
export SUNO_ACCOUNT_1_COOKIE='authorization=2ecbb570-11ab-4741-8151-cc2e9f866adf; g_state={"i_l":0,"i_ll":1776412580330,"i_e":{"enable_itp_optimization":19},"i_et":1776397639153,"i_b":"udGkYWpiTfRTG1psNBSi4XuFCGXy//gDUqfHvlNy54c"}'

mix phx.server
