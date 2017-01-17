#!/bin/bash

#IFS=$'\n'
RED='\033[0;31m'
GREEN='\033[0;32m'
GRAY='\033[0;37m'
NC='\033[0m'


############################## DIRECTORY ##############################
dir=""
while true
do
	echo
	echo "STEP 1"
	echo "Choose directory:"
	ls -d */
	read dir
	if [ ! -d "$dir" ]
	then
		echo "No such directory."
	else
		break
	fi
done

############################## USERS ##############################
echo "Users:"
unset users
userNumber=0	#0 --- author
for user in $(ls -d $dir/*/)
do
	user=${user%%/}
	user=${user##*/}
	if [ $user = "автор" ]
	then
		users[0]=$user
	else
		userNumber=$(($userNumber + 1))
		users[$userNumber]=$user
	fi
done

for (( i = 1; i <= userNumber; i++))
do
	echo ${users[$i]}
done

############################## LANGUAGE ##############################
suff=""
while true
do
	echo
	echo "STEP 2"
	echo "Choose code suffix: pas, c, cpp"
	read suff
	case "$suff" in
	"pas") 
		echo "fpc"; 
		break;;
	"c") 
		echo "gcc -Wall"; 
		break;;
	"cpp") 
		echo "g++ -Wall"; 
		break;;
	*) 
		echo "Try again";;
	esac
done

############################## FILES ##############################
echo
echo "User files:"

spaces=""
for (( i = 0; i < 15; i++))
do
	spaces=$spaces" "
done

problems=10; #max is 10

echo -n "$spaces"
for (( problem=1; problem <= problems; problem++ ))
do
	echo -n "$problem  "
done
echo

> check-rename.log

for name in ${users[@]}
do
	echo -n "$name${spaces:${#name}}"
	sum=0
	for (( problem=1; problem <= problems; problem++ ))
	do
		userdir="$dir/$name"
		template="*$problem.$suff"
		
		filename="$userdir/$problem.$suff"
		for badfilename in $(find $userdir -name $template)
		do
			if [ "$badfilename" != "$filename" ]
			then
				mv -v "$badfilename" "$filename" >> check-rename.log
			fi
		done
		
		if [ -f $filename ]
		then
			echo -n -e "${GREEN}+  "
			sum=$(($sum+1))
		else
			echo -n -e "${RED}-  "
		fi
	done
	echo -e "${NC} $sum"
done

echo
echo "Show check-rename.log? (default = no)"
echo "y/n"
read ans
if [ "$ans" == "y" ]
then
	cat check-rename.log
fi

############################## PLAGIAT ##############################
echo
echo "STEP 3"
echo "Check plagiat? (default = no)"
echo "y/n"
read ans
if [ "$ans" = "y" ]
then
	> check-plagiat.log
	for (( problem=1; problem <= problems; problem++ ))
	do
		echo "Problem #$problem"
		echo "Problem #$problem" >> check-plagiat.log
		for (( i = 1; i <= userNumber; i++ ))
		do
			file1="$dir/${users[$i]}/$problem.$suff" 
			unset list
			for (( j = 1; j <= userNumber; j++ ))
			do
				file2="$dir/${users[$j]}/$problem.$suff" 
				if [ -f "$file1" ] && [ -f "$file2" ] && [ "$file1" != "$file2" ]
				then
					if diff -B -w -b "$file1" "$file2" &> /dev/null
					then
						list+="${users[$j]} "
					fi
				fi				
			done
			if [ ! -z $list ]
			then
				echo ${users[$i]} : $list
				echo ${users[$i]} : $list >> check-plagiat.log
			fi
		done
		echo
		echo >> check-plagiat.log
	done
	
	echo
	echo "Show check-plagiat.log? (default = no)"
	echo "y/n"
	read ans
	if [ "$ans" == "y" ]
	then
		cat check-plagiat.log
	fi
fi

############################## COMPILE ##############################
echo
echo "STEP 4"
echo "Compile? (default = yes)"
echo "y/n"
read ans
if [ "$ans" != "n" ]
then
	> check-compile.log
	echo -n "$spaces"
	for (( problem=1; problem <= problems; problem++ ))
	do
		echo -n "$problem  "
	done
	echo
	
	for name in ${users[@]}
	do
		sum=0
		echo -n "$name${spaces:${#name}}"
		for (( problem=1; problem <= problems; problem++ ))
		do
			userdir="$dir/$name"
			filename="$userdir/$problem.$suff"
			binaryname="$userdir/$problem"
			unset result
			if [ -f $filename ]
			then
				case "$suff" in
				"pas") 
					result=$(fpc $filename 2>&1);;
				"c") 
					result=$(gcc $filename -Wall -o $binaryname -lm 2>&1);;
				"cpp")
					result=$(g++ $filename -Wall -o $binaryname -lm 2>&1);;
				*) 
					echo "Error";;
				esac

				if [ $? -eq 0 ]
				then
					echo -n -e "${GREEN}+  "
					sum=$(($sum+1))
				else
					echo -n -e "${RED}x  "
				fi				

				if [ -n "$result" ]
				then
					printf "$name $problem:\n" >> check-compile.log
					printf "%s\n\n" "$result" >> check-compile.log
				fi
			else
				echo -n -e "${RED}-  "
			fi
		done
		echo -e "${NC} $sum"
	done  
	echo
	echo "Show check-compile.log? (default = no)"
	echo "y/n"
	read ans
	if [ "$ans" == "y" ]
	then
		grep -v "^$" check-compile.log
	fi
fi


############################## RUN ##############################

echo
echo "STEP 5"

unset ${result[@]}
for ((p = 0; p < problems; p++ )) 
do
	result[$p]="-"
done

for ((i = 0; i <= userNumber; i++ )) 
do
	name=${users[$i]}
	resultfilename="$dir/$name/result.txt"
	> $resultfilename
	printf "%s\n" "${result[@]}" > $resultfilename
done

while true
do
	clear
	echo -n "Run program #:"
	read problem
	if  [ "$problem" -lt 1 ] || [ "$problem" -gt "$problems" ]
	then
		exit 0
	fi

	echo "Enter no input data if you want read from file 'f.txt'."
	echo "Start input with '-' if you want run with arguments."
	read input
	if [[ -z $input ]]
	then
		cat f.txt
		echo
	fi

	echo "File output? (default = no)"
	echo "Enter no input if you don't want print output file"
	read fileout
	if [[ ! -z $fileout ]]
	then
		echo "Print *.txt"
		echo
	fi

	for ((i = 0; i <= userNumber; i++ )) 
	do
		res="0"
		name=${users[$i]}
		filename="$dir/$name/$problem"
		resultfilename="$dir/$name/result.txt"

		if [ -f $filename ]
		then
			after=""
			before=""
			if [[ ! -z $fileout ]]
			then
				before=$(ls --time-style='+%H:%M:%S' -ltu | grep txt | head -n 1)
			fi

			echo $name
			if [[ -z $input ]]
			then
				cat f.txt | timeout 0.01 "$filename"
			else
				if [[ ${input:0:1} == "-" ]]
				then
					run="$filename ${input:1}"
					echo "command line arguments: $run"
					timeout 0.01 $run
				else
					echo "$input" | timeout 0.01 "$filename"
				fi
			fi

			if [[ ! -z $fileout ]]
			then
				after=$(ls --time-style='+%H:%M:%S' -ltu | grep txt | head -n 1)

				if [ "$after" != "$before" ]
				then
					echo "Last modificated file:"
					echo $after
					a=$(ls --time-style='+%H:%M:%S' -tu| grep txt | head -n 1)
					cat $a
					echo
				fi
			fi

			echo
			echo -n "Correct (default = yes, y/n): "
			read ans
			if [ "$ans" = "n" ]
			then
				res="0"
			else
				res="1"
			fi
			echo

			if [[ ! -z $fileout ]]
			then
				if [ "$after" != "$before" ]
				then
					rm $a
				fi
			fi

		else
			res="-"
		fi

		readarray -t result < $resultfilename
		if [ ${result[$problem-1]} = "-" ]
		then
			result[$problem-1]=$res
		elif [ ${result[$problem-1]} = "1" ] && [ $res = "0" ]
		then
			result[$problem-1]="0"
		fi

		printf "%s\n" "${result[@]}" > $resultfilename
	done


	for ((i = 0; i <= userNumber; i++ ))
	do
		name=${users[$i]}
		echo -n "$name${spaces:${#name}}"

		resultfilename="$dir/$name/result.txt"
		readarray -t result < $resultfilename
		sum=0
		for r in ${result[@]}
		do
			if [ $r = "1" ]
			then
				sum=$(($sum+1))
			fi
			
			if [ $r = "1" ]
			then
				echo -n -e "${GREEN}+  "
			elif [ $r = "0" ]
			then
				echo -n -e "${RED}x  "
			else
				echo -n -e "${RED}-  "
			fi
		done
		echo -e "${NC} $sum"
	done
	echo "Exit? (x)"
	read problem
	if [ $problem = "x" ]
	then
		break
	fi
done

############################## OUTPUT RESULT ##############################
echo
clear
> "$dir/result.txt"

echo -n "$spaces"
echo -n "Имя " >> "$dir/result.txt"
for (( problem=1; problem <= problems; problem++ ))
do
	echo -n "$problem "
	echo -n "$problem " >> "$dir/result.txt"
done

echo "Итог"
echo "Итог" >> "$dir/result.txt"

for ((i = 1; i <= userNumber; i++ ))
do
	name=${users[$i]}
	echo -n "$name${spaces:${#name}}"
	echo -n "$name " >> "$dir/result.txt"

	resultfilename="$dir/$name/result.txt"
	readarray -t result < $resultfilename
	sum=0	

	for r in ${result[@]}
	do
		if [ $r == "1" ]
		then
			sum=$(($sum+1))
		fi
		
		if [ $r == "1" ]
		then
			echo -n -e "${GREEN}+ "
			echo -n "1 " >> "$dir/result.txt"
		elif [ $r == "0" ]
		then
			echo -n -e "${RED}x "
			echo -n "0 " >> "$dir/result.txt"
		else
			echo -n -e "${RED}- "
			echo -n "- " >> "$dir/result.txt"
		fi
	done
	echo -e "${NC} $sum"
	echo "$sum" >> "$dir/result.txt"
done

exit 0
