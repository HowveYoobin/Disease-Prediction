mport argparse
import os
import pandas as pd

if __name__=="__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", type = str, default= None, help="Directory wit\
h preprocessed files")
    parser.add_argument("--tar", type = str, default = None, help = "Target var\
iable (Phenotype)")
    parser.add_argument("--vars", type = str, default=None, help="Variables")
    parser.add_argument("--out", type = str, default=None, help = "Name of outp\
ut file")

    args = parser.parse_args()

    file_list = os.listdir(args.dir)
    file_dict = {}

    #print(file_list)                                                           
    for file_name in file_list:
        prefix = file_name.split("_")[0]
        file_dict[prefix] = [file for file in file_list if prefix in file]

    # print(file_dict)                                                          

    # 파일의 prefix대로 분류하여 같은 prefix 파일들을 열 방향으로 merge         
    for ind, k in enumerate(file_dict.keys()):
        for idx, file_name in enumerate(file_dict[k]):
            # 파일 이름의 suffix를 열 이름으로 지정                             
            col_name = ["DIST_ID", file_name.split("_")[1].split(".")[0]]
            if idx == 0: # 데이터 프레임 초기화                                 
                merged_df = pd.read_csv(args.dir + "/" + file_name, sep = " ", \
names = col_name, header = 0)
            else: # 데이터 프레임 합치기 ( 열 방향으로)                         
                df_to_merge = pd.read_csv(args.dir + "/" + file_name, sep= " ",\
 names = col_name, header = 0)
                merged_df = pd.merge(merged_df, df_to_merge, on = "DIST_ID", ho\
w = "outer") # 어느 한쪽으로라도 없는 데이터가 있는 경우 NaN 값 지정            

        # 행 방향으로 suffix 기준으로 열 같은 것끼리 합치기 (concat)            
        if ind == 0: # 데이터 프레임 초기화                                     
            concat_df = merged_df
        else: # 데이터 프레임 행 방향으로 합치기                              
            concat_df = pd.concat([concat_df, merged_df], axis = 0, ignore_inde\
x = True, sort = False)

    # variable 넣어준 순서대로 칼럼 정렬                                        
    cols = [var for var in args.vars.split(",") if var in concat_df.columns]
    cols.insert(0,"DIST_ID")
    concat_df = concat_df[cols]

    # "DIST_ID" 기준으로 오름차순 정렬                                          
    concat_df = concat_df.sort_values(by="DIST_ID", ascending = True)
    pheno_df = concat_df[['DIST_ID', args.tar]]

    concat_df.to_csv(args.dir + "/" + args.out + ".csv", index = False, sep = "\
 ")
    pheno_df.to_csv(args.dir + "/" + args.out + "_pheno.csv", index = False, se\
p =" ")
