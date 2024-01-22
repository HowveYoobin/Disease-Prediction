file_name=""; dir_name=""; var=""; pheno="";
file_flag=0; dir_flag=0; var_flag=0; phe_flag=0; index=0

function print_help {
    echo "-------------------------"
    echo "-f : File name"
    echo "-d : Directory name"
    echo "-v : Variable"
    echo "-p : Target phenotype"
    echo "-o : Output directory name"
    echo "-h : Print help"
    echo "-------------------------"
}

function process_file {
    # 파일의 확장자 추출                                                        
    extension="${file_name##*.}"

    # 파일이 gzip으로 압축되어 있는지 확인                                      
    if [ "$extension" = "gz" ]; then

        # gzip으로 압축 해제한 내용을 file 변수에 저장                          
        gzip -d "$file_name"
        file=$(echo "$file_name" | sed 's/\.gz$//')
    else
        # gzip으로 압축되어 있지 않은 경우 파일 내용을 그대로 file 변수에 저장  
        file=$file_name
    fi

    prefix=$(echo $file_name | cut -d '_' -f 1)

    #echo $file                                                                 
    #echo $prefix                                                               

    sed -i 's/,/ /g' "$file"
    sed -i 's/^M//g' "$file"
    if [ $var_flag -eq 1 ]; then
        IFS=',' read -ra var_array <<< "$var"

        for var_item in "${var_array[@]}"; do
            prefix_var="${prefix}_${var_item}"

            #echo $prefix_var                                                   
            if awk -v target="$prefix_var" 'BEGIN{found=0} {for(i=1;i<=NF;i++){\
if($i==target){found=1}}} END{exit !found}' "$file"; then
               index=$(awk -v target="$prefix_var" 'BEGIN{FS=OFS=" "} {for(i=1;\
i<=NF;i++){if($i==target){print i}}}' "$file")
               echo "Index for $prefix_var in $file: $index"

               awk '{print $1, $'$index'}' "$file" > "../${out}/${prefix_var}.c\
sv"

            fi
        done
    fi

    #awk '{print $1, $'$index'}' "$file" > ../preprocessed_csv/"$prefix_var".cs\
v                                                                               
}

function merge {
    if [ $phe_flag -eq 1 ]; then
        merged=$(python3 ./merger.py --dir "$1" --tar "$pheno" --vars "$var" --\
out "$out" 2>&1) | echo "Saved $out.csv and ${out}_pheno.csv files in $out dire\
ctory"

    else
        merged=$(python3 ./merger.py --dir "$1" --vars "$var" --out "$out" 2>&1\
) | echo "Saved $out.csv file in $out directory"
fi
}

while getopts "f:d:p:v:o:" opt
do
    case $opt in
        f) file_name="$OPTARG"; file_flag=1;;
        d) dir_name="$OPTARG"; dir_flag=1;;
        p) pheno="$OPTARG"; phe_flag=1;;
        v) var="$OPTARG"; var_flag=1;;
        o) out="$OPTARG"; out_flag=1;;
        *) print_help; exit;;
        :) case $OPTARG in
               f) print_help;;
               d) print_help;;
               v) print_help;;
           esac; exit;;
    esac
done

#cd ./raw_csv/                                                                  

if [ $# -eq 0 ]; then
    print_help
    exit
fi

if [ $out_flag -eq 1 ]; then
    mkdir -p "$out"
    echo "Output files will be saved in $out directory."
fi

if [ $file_flag -eq 1 ]; then
    if [ ! -e "$file_name" ]; then
        echo "File does not exist"
        exit
    fi
fi

if [ $dir_flag -eq 1 ]; then
    if [ ! -d "$dir_name" ]; then
        echo "Directory does not exist"
        exit
    fi

    cd "$dir_name"

    for file_name in *; do
        process_file "$file_name"
    done

    cd ".."

    merge "$out"

    echo "Preprocessing Completed. Check out $out"

fi
