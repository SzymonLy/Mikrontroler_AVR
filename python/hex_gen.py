from check_calc import checksum_calculation


import sys
if __name__ == "__main__":
    n_of_DPUS = int(sys.argv[1])
    
i=0
#first file is for cpu, others are for 
#files = [r'my_hex_cpu.hex',r'my_hex1.hex',r'my_hex2.hex'] 
files = [r'cpu_hex.hex'] 
while i < n_of_DPUS:
    files.append(r'dpu_hex.hex')
    i = i + 1
i = 0;
data = ""
with open(r'my_new_hex.hexn', 'w') as out_f: 
    for x in files:
        with open(x, 'r') as file: 
            lines = file.readlines() 
            checksum = checksum_calculation([0x02,0x04,i])
            if i < 16 :
                newline = ":02000004000" + format(i,'x') + format(checksum, 'x') + "\n"
            else:
                newline = ":0200000400" + format(i,'x') + format(checksum, 'x') + "\n"
            data = data + newline
            for line in lines:
                if line != ':00000001FF\n' and line != ':00000001FF':
                    data = data + line
            #out_f.writelines(lines[:-1]) #= data + str(lines[:-1])   
        i=i+1
    endline = ":00000001FF"
    #out_f.writelines(endline)
    #filedata = out_f.read()
    #filedata = filedata.replace(':', '31')
   
    data = data + endline
    
    #filedata =out_f.read()
    

    new_string = data.replace(":", "3a")
   # data.replace(search_text, replace_text) 
    out_f.write(new_string)
#print (data)


#will create file if the file does not exist



