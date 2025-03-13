#number = 0x020FF0040001F2


def checksum_calculation(numbers):
    
    #numbers = [0x02,0x04,0x02]

    def bit_not(n, numbits=8):
        return (1 << numbits) - 1 - n
        
    checksum = 0
    for x in numbers:
        checksum = checksum + x

    while checksum >255 :
        checksum = checksum-255
    checksum = bit_not(checksum)
    checksum = checksum + 1
    return checksum

checksum = checksum_calculation([0x02,0x04,0x02])
#print(str(hex(checksum)))