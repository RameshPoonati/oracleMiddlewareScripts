#!/bin/bash
dir=$1

for file in $dir/*;do
#s1=`sed 's/!/ /g; s/</ /g; s/>/ /g; s/\[/ /g; s/\]/ /g; s/\// /g; s/"/ /g; s/(/ /g; s/)/ /g; s/=/ /g;' $dir/0000M^6veqODScC_vD^AyX1SOcWr00RFjF | grep Invoke_UCMPersonService | grep -o -P '(?<=Invoke_UCMPersonService  date).*?(?<=Invoked 2-way operation  createPerson  on partner  UCMPersonService)'` #Removes special characters and searches for the string.

unset timeArray
#echo "$dir $file"
s1=`sed 's/!/ /g; s/</ /g; s/>/ /g; s/\[/ /g; s/\]/ /g; s/\// /g; s/"/ /g; s/(/ /g; s/)/ /g; s/=/ /g;' $file | grep Invoke_UCMPersonService | grep -o -P '(?<=Invoke_UCMPersonService  date).*?(?<=Invoked 2-way operation  createPerson  on partner  UCMPersonService)'` #Change search string as needed.

#echo $s1

for string in $s1
do
	#echo $string
	if [[ $string =~ [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}\+[0-9]{2}:[0-9]{2} ]]; then #check if the string is time stamp.
	#	echo $?
		s2=`echo $string | tr "T" " " | cut -f1 -d"+"` #convert to standard unix format.
		#timeArray+=("$s2")
		timeArray+=(`date -d "$s2" +%s.%N`) #Convert to Epoch format and insert into an array.
#		echo $s2
	fi
done

#for ((i = 0; i < ${#timeArray[@]}; i++))
#do
#    echo "${timeArray[$i]}"
#done

s3=`echo print ${timeArray[1]}-${timeArray[0]} | perl`
echo -n "$file : "
#printf $file ": "
printf "%.3g\n" $s3
done
