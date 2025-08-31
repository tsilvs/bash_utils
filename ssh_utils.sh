#!/bin/bash

# add_ssh_keys () {
# 	ssh-add -l || eval "$(ssh-agent -s)";
# 	for key in ~/.ssh/*;
# 	do
# 		[[ -f "$key" && $(head -n1 "$key") =~ "PRIVATE KEY" ]] && ssh-add "$key";
# 	done
# }

# ssh.fs.diff() {
# 	local user="${1:-"$(id -un)"}"
# 	shift 1 # TODO: add `[if $1 not empty]` condition
# 	local suffix="${1:-".lan.001"}"
# 	shift 1 # TODO: add `[if $1 not empty]` condition
# 	local host="${1:?"Host is required"}"
# 	shift 1 # TODO: add `[if $1 not empty]` condition
# 	local ignore="${1:-""}"
# 	diff \
# 		<(ssh -o IdentitiesOnly=yes -i "~/.ssh/${user}${suffix}" "${user}@${host}" find -path "${ignore}" -prune ${path1} -printf '"%8s %P\n"') \
# 		<(find ${path2} -printf '%8s %P\n')
# }

# diff \
# 	<(ssh -o IdentitiesOnly=yes -i "~/.ssh/$(id -un).lan.001" "$(id -un)@${host}" tree -a --gitignore -I 'bin' -I 'models' -I 'db' -I 'Media' -I 'DL' -I '.cache' -I '.git' -I '0.Mix' -I 'mydb' -I 'myrepo' -I '.pnpm-store' -I '.Trash-1000' -I 'lost+found' -I '1.vm.d' -I 'linux-roots' -F --noreport --dirsfirst -i -f -L 4 -d /$pathtodata/ | sed 's|/$pathtodata||g') \
# 	<(tree -a --gitignore -I 'bin' -I 'models' -I 'db' -I 'Media' -I 'DL' -I '.cache' -I '.git' -I '0.Mix' -I 'mydb' -I 'myrepo' -I '.pnpm-store' -I '.Trash-1000' -I 'lost+found' -I '1.vm.d' -I 'linux-roots' -F --noreport --dirsfirst -i -f -L 4 -d /$pathtodata/ | sed 's|/$pathtodata||g')

# user_host=$1
# remote_dir=$2
# local_dir=$3
# shift 3
# exclude_dirs=("$@")

# # Build exclude arguments for find
# exclude_args_remote=()
# exclude_args_local=()
# for dir in "${exclude_dirs[@]}"; do
# 	exclude_args_remote+=( -path "$remote_dir/$dir" -prune -o )
# 	exclude_args_local+=( -path "$local_dir/$dir" -prune -o )
# done

# # Remote find command
# remote_find_cmd="find $remote_dir ${exclude_args_remote[*]} -print"

# # Local find command
# local_find_cmd="find $local_dir ${exclude_args_local[*]} -print"

# # Compare outputs
# diff <(ssh -o IdentitiesOnly=yes $user_host "$remote_find_cmd") <(eval "$local_find_cmd")

# Compress a list of files on the remote

# ssh user@remote "cd /path/to/directory && tar -cvf allfiles.tar -T -" < mylist.txt