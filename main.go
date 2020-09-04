package main

//import "proyecto1_MIA/sergio_parser"
import (
	"proyecto1_MIA/sergio_parser"
	"bytes"
	"encoding/binary"
	"fmt"
	"log"
	"os"
	"unsafe"
    "time" 
    "math/rand"
)

// Struct particion
type partition struct { //3
	Status byte
	PartType byte
	Fit byte
	Start int64
	Size int64
	Name [16] byte
}
var signatures [100]uint8
// Struct MBR
type mbr struct { 
	Size int64
	Date [19]byte
	DiskSignature uint8
	Part1 partition
	Part2 partition
	Part3 partition
    Part4 partition
}



func main() {
	sergio_parser.Execute()
	createDisk()
	//mbr :=readFile("Hoja1_201020252.bin")
	//mbrReport(mbr)
}

func randomNum() uint8{
	rand.Seed(time.Now().UnixNano())
	x:=rand.Intn(255)
	c:=uint8(x)
	flag :=false
	for i:= 0; i< len(signatures); i++{
		if c==signatures[i]{
			flag =true
		}
	}
	if flag {
		randomNum()
	}
	return c
}

func getDate() [19]byte { //devuelvo en byte la fecha de una vez
var char [19]byte
t := time.Now()
fecha := fmt.Sprintf("%d-%02d-%02dT%02d:%02d:%02d",
	t.Year(), t.Month(), t.Day(),
	t.Hour(), t.Minute(), t.Second())
fmt.Println("La fecha actual es =>", fecha)
copy(char[:], fecha)
return char
}

func createDisk(){
	file, err := os.Create("Hoja1_201020252.bin")
	defer file.Close()
	if err != nil{
		log.Fatal(err)
	}
	x:=int64(5242880)
	mbr:=createMBR(int64(x))
	s:=&mbr
	var binario2 bytes.Buffer
	binary.Write(&binario2, binary.BigEndian, s)
	writeNextBytes(file, binario2.Bytes())

	var binario bytes.Buffer
	var n uint8
	file.Seek(x, int (unsafe.Sizeof(mbr)))
	binary.Write(&binario, binary.BigEndian, n)
	writeNextBytes(file, binario.Bytes())
}


func writeNextBytes(file *os.File, bytes []byte) {

	_, err := file.Write(bytes)

	if err != nil {
		log.Fatal(err)
	}

}

func createMBR(x int64) mbr{
	mbr:=mbr{}
	mbr.Size=x //size disco
	var c [19]byte
	c =getDate()//fecha
	copy(mbr.Date[:], c[:])
	//disk?signatura
	mbr.DiskSignature = randomNum()

	//part1
	name:= "Part1"
	var nameParameter[16]byte
	copy(nameParameter[:], name)
	var inicio int64
	inicio=int64(unsafe.Sizeof(mbr))
	mbr.Part1 = mbrPartition('1', 'P','W', inicio, 20000, nameParameter)

	//part2
	inicio= inicio+20000
	name= "Part2"
	copy(nameParameter[:], name)
	mbr.Part2 = mbrPartition('1', 'P','W', inicio, 18000, nameParameter)

	//part3
	inicio= inicio+18000
	name= "Part3"
	copy(nameParameter[:], name)
	mbr.Part3 = mbrPartition('1', 'P','W', inicio, 100000, nameParameter)

	//part4	
	inicio= inicio+100000
	name= "Part4"
	copy(nameParameter[:], name)
	mbr.Part4 = mbrPartition('1', 'E','W', inicio, 624000, nameParameter)
 return mbr
}


func mbrPartition(status byte, tipo byte, fit byte, start int64,size int64, name[16]byte)partition{
partition:= partition{}
partition.Status = status
partition.PartType = tipo
partition.Fit = fit 
partition.Start = start
partition.Size = size
partition.Name = name 
return partition
}



