#
# Copyright 2017 Shivansh Rai
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $FreeBSD$
#

check_acl()
{
	# Check if POSIX.1e ACLs are enabled on the root partition.
	fs=`df . | awk '$NF ~ "/" {print $1}'`
	if mount | awk -v fs=$fs '$1 == fs' | grep -q acls &&
	   tunefs -p "$fs" 2>&1 | awk '$2 == "POSIX.1e" {print $5}' | grep -q enabled; then
	    # ok
	else
	   atf_skip "POSIX.1e ACLs are not enabled"
	fi
}

get_user()
{
	stat -f "%Su" "$1"
}

get_group()
{
	stat -f "%Sg" "$1"
}

get_user_perm()
{
	stat -f "%SHp" "$1"
}

get_group_perm()
{
	stat -f "%SMp" "$1"
}

get_other_perm()
{
	stat -f "%SLp" "$1"
}

atf_test_case no_opt
no_opt_head()
{
	atf_set "descr" "Verify the output of the getfacl(1) command " \
			"without any options."
	atf_set "require.user" "root"
}

no_opt_body()
{
	check_acl
	atf_check touch A
	atf_check setfacl -m u::rw,g::r,o::r A
	user_A=$(get_user A)
	group_A=$(get_group A)
	user_perm_A=$(get_user_perm A)
	group_perm_A=$(get_group_perm A)
	other_perm_A=$(get_other_perm A)
	atf_check -o inline:'# file: A\n# owner: '"$user_A"'\n# group: '"$group_A"'\nuser::'"$user_perm_A"'\ngroup::'"$group_perm_A"'\nmask::'"$group_perm_A"'\nother::'"$other_perm_A"'\n' getfacl A
}

atf_test_case no_opt_symbolic
no_opt_symbolic_head()
{
	atf_set "descr" "Verify that if the target of the operation is a symbolic " \
			"link, then getfacl(1) returns the ACL from the source of " \
			"the symbolic link."
	atf_set "require.user" "root"
}

no_opt_symbolic_body()
{
	check_acl
	atf_check touch A
	atf_check setfacl -m u::rw,g::r,o::r A
	atf_check ln -s A B
	user_A=$(get_user A)
	group_A=$(get_group A)
	user_perm_A=$(get_user_perm A)
	group_perm_A=$(get_group_perm A)
	other_perm_A=$(get_other_perm A)
	atf_check -o inline:'# file: B\n# owner: '"$user_A"'\n# group: '"$group_A"'\nuser::'"$user_perm_A"'\ngroup::'"$group_perm_A"'\nmask::'"$group_perm_A"'\nother::'"$other_perm_A"'\n' getfacl B
}

atf_test_case h_flag
h_flag_head()
{
	atf_set "descr" "Verify that if the target of the operation is a symbolic " \
			"link, then '-h' option returns the ACL from the symbolic " \
			"link rather than following the link."
	atf_set "require.user" "root"
}

h_flag_body()
{
	check_acl
	atf_check touch A
	atf_check setfacl -m u::rw,g::r,o::r A
	atf_check ln -s A B
	user_perm_B=$(get_user_perm B)
	group_perm_B=$(get_group_perm B)
	other_perm_B=$(get_other_perm B)
	atf_check -o inline:'user::'"$user_perm_B"'\ngroup::'"$group_perm_B"'\nother::'"$other_perm_B"'\n' getfacl -hq B
}

atf_test_case q_flag
q_flag_head()
{
	atf_set "descr" "Verify that '-q' option does not display commented " \
			"information about file name and ownership."
	atf_set "require.user" "root"
}

q_flag_body()
{
	check_acl
	atf_check touch A
	atf_check setfacl -m u::rw,g::r,o::r A
	user_perm_A=$(get_user_perm A)
	group_perm_A=$(get_group_perm A)
	other_perm_A=$(get_other_perm A)
	atf_check -o inline:'user::'"$user_perm_A"'\ngroup::'"$group_perm_A"'\nmask::'"$group_perm_A"'\nother::'"$other_perm_A"'\n' getfacl -q A
}

atf_init_test_cases()
{
	atf_add_test_case no_opt
	atf_add_test_case no_opt_symbolic
	atf_add_test_case h_flag
	atf_add_test_case q_flag
}
