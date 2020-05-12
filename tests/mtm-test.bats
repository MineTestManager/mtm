#!/usr/bin/env bats



setup() {
#  echo "$BATS_TMPDIR" >&2
  root_dir="$BATS_TMPDIR/mtm-root"
  mkdir "$root_dir"
  cp -r .mtm "$root_dir"
  cd "$root_dir"
  export MTM_TESTSWITCH="ON"
#  .mtm/mtm.sh >&2
  mtm_version="v0.0.1-dev"
}

teardown() {
    unset MTM_TESTSWITCH
    cd "$BATS_TMPDIR"
    rm -rf "$root_dir"
}



@test "unknown command" {
  run .mtm/mtm.sh foobar
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "mtm.sh: MineTestManager (mtm) $mtm_version by 65194270+ShihanAlma@users.noreply.github.com" ]
  [ "${lines[1]}" = "mtm.sh: unknown command foobar." ]
  [ "${lines[2]}" = "mtm.sh: To list all instances use" ]
  [ "${lines[3]}" = ".mtm/mtm.sh [list]" ]
}


@test "without command empty root" {
  run .mtm/mtm.sh
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "mtm.sh: MineTestManager (mtm) $mtm_version by 65194270+ShihanAlma@users.noreply.github.com" ]
  [ "${lines[1]}" = "mtm.sh: No instances yet in $root_dir" ]
  [ "${lines[2]}" = "mtm.sh: To create an instances use" ]
  [ "${lines[3]}" = ".mtm/mtm.sh setup [instance_name]" ]
}
@test "list empty root" {
  run .mtm/mtm.sh list
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "mtm.sh: MineTestManager (mtm) $mtm_version by 65194270+ShihanAlma@users.noreply.github.com" ]
  [ "${lines[1]}" = "mtm.sh: No instances yet in $root_dir" ]
  [ "${lines[2]}" = "mtm.sh: To create an instances use" ]
  [ "${lines[3]}" = ".mtm/mtm.sh setup [instance_name]" ]
}


@test "without command instances" {
  mkdir instance1
  mkdir instance2
  run .mtm/mtm.sh
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "mtm.sh: MineTestManager (mtm) $mtm_version by 65194270+ShihanAlma@users.noreply.github.com" ]
  [ "${lines[1]}" = "mtm.sh: Instances in $root_dir:" ]
  [ "${lines[2]}" = "instance1" ]
  [ "${lines[3]}" = "instance2" ]
  [ "${lines[4]}" = "mtm.sh: To check an instance use" ]
  [ "${lines[5]}" = ".mtm/mtm.sh check [instance_name]" ]
}
@test "list instances" {
  mkdir instance1
  mkdir instance2
  run .mtm/mtm.sh list
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "mtm.sh: MineTestManager (mtm) $mtm_version by 65194270+ShihanAlma@users.noreply.github.com" ]
  [ "${lines[1]}" = "mtm.sh: Instances in $root_dir:" ]
  [ "${lines[2]}" = "instance1" ]
  [ "${lines[3]}" = "instance2" ]
  [ "${lines[4]}" = "mtm.sh: To check an instance use" ]
  [ "${lines[5]}" = ".mtm/mtm.sh check [instance_name]" ]
}


@test "check .mtm" {
  run .mtm/mtm.sh check .mtm
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "mtm.sh: MineTestManager (mtm) $mtm_version by 65194270+ShihanAlma@users.noreply.github.com" ]
  [ "${lines[1]}" = "mtm.sh: .mtm is the MintestManger Script directory! Dont use it as instance!" ]
  [ "${lines[2]}" = "mtm.sh: To list all instances use" ]
  [ "${lines[3]}" = ".mtm/mtm.sh [list]" ]
}
@test "check noinstance" {
  run .mtm/mtm.sh check noinstance
  [ "$status" -eq 10 ]
  [ "${lines[0]}" = "mtm.sh: MineTestManager (mtm) $mtm_version by 65194270+ShihanAlma@users.noreply.github.com" ]
  [ "${lines[1]}" = "mtm.sh: check for instance named noinstance in $root_dir ..." ]
  [ "${lines[2]}" = "mtm.sh: No instance named noinstance in $root_dir!" ]
  [ "${lines[3]}" = "mtm.sh: To list all instances use" ]
  [ "${lines[4]}" = ".mtm/mtm.sh [list]" ]
}
@test "check empty instance" {
  mkdir instance1
  run .mtm/mtm.sh check instance1
  [ "$status" -eq 10 ]
  [ "${lines[0]}" = "mtm.sh: MineTestManager (mtm) $mtm_version by 65194270+ShihanAlma@users.noreply.github.com" ]
  [ "${lines[1]}" = "mtm.sh: check for instance named instance1 in $root_dir ..." ]
  [ "${lines[2]}" = "mtm.sh: Found instance named instance1 in $root_dir!" ]
  [ "${lines[3]}" = "mtm.sh: check for Minetest in instance instance1 in $root_dir ..." ]
  [ "${lines[4]}" = "mtm.sh: No Minetest Binary in instance instance1 in $root_dir!" ]
  [ "${lines[5]}" = "mtm.sh: To setup an instances use" ]
  [ "${lines[6]}" = ".mtm/mtm.sh setup [instance_name]" ]
}

# ToDo in Arbeit. An Änderungen anpassen
@test "setup instance" {
  run .mtm/mtm.sh setup instance1 craftguide
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "mtm.sh: MineTestManager (mtm) $mtm_version by 65194270+ShihanAlma@users.noreply.github.com" ]
  [ "${lines[1]}" = "mtm.sh: check for instance named instance1 in $root_dir ..." ]
  [ "${lines[2]}" = "mtm.sh: No instance named instance1 in $root_dir!" ]
  [ "${lines[3]}" = "mtm.sh: Create instance dir $root_dir/instance1!" ]
  [ "${lines[4]}" = "mtm.sh: check for Minetest in instance instance1 in $root_dir ..." ]
  [ "${lines[5]}" = "mtm.sh: No Minetest Binary in instance instance1 in $root_dir!" ]
  [ "${lines[6]}" = "mtm.sh: Download Minetest latest version to $root_dir/.mtm_tmp ..." ]
  run .mtm/mtm.sh check instance1 craftguide
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "mtm.sh: MineTestManager (mtm) $mtm_version by 65194270+ShihanAlma@users.noreply.github.com" ]
  [ "${lines[1]}" = "mtm.sh: check for instance named instance1 in $root_dir ..." ]
  [ "${lines[2]}" = "mtm.sh: Found instance named instance1 in $root_dir!" ]
  [ "${lines[3]}" = "mtm.sh: check for Minetest in instance instance1 in $root_dir ..." ]
  [ "${lines[4]}" = "mtm.sh: Found Mintest in instance instance1 in $root_dir!" ]
}

