#!/bin/bash

:test:can_sudo()
{
   sudo -n true &>/dev/null
}
