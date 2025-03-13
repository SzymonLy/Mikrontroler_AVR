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
with open(r'my_new_bin.bin', 'wb') as out_f: 
    for x in files:
        with open(x, 'r') as file: 
            lines = file.readlines() 
            checksum = checksum_calculation([0x02,0x04,i])
            if i < 16 :
                newline = ":02000004000" + format(i,'x') + format(checksum, 'x')
            else:
                newline = ":0200000400" + format(i,'x') + format(checksum, 'x')
            data = data + newline
            for line in lines:
                if line != ':00000001FF\n' and line != ':00000001FF\n':
                    data = data + line
            #out_f.writelines(lines[:-1]) #= data + str(lines[:-1])   
        i=i+1
    endline = ":00000001FF"
    #out_f.writelines(endline)
    #filedata = out_f.read()
    #filedata = filedata.replace(':', '31')
   
    data = data + endline
    
    #filedata =out_f.read()
    
    nums = []
    new_string = data.replace(":", "3a")
    new_string = new_string.replace("\n", "")
    


    
    for i in range(0, len(new_string), 2):
        code = new_string[i:i+2]
        code2 = int(code, 16)
        # nums.append(code2)
        # nums.append(code2)
        nums.append(code2) #reapet 3 times 
        
        

   #hex_data = bytearray(new_string, 'ASCII')
   # data.replace(search_text, replace_text) 
    out_f.write(bytearray(nums))
#print (data)


#will create file if the file does not exist



