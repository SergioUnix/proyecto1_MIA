%{
package sergio_parser

import (
  "fmt"
  "bytes"
  "io"
  "bufio"
	"os"
  "bytes"
	"encoding/binary"
	"fmt"
	"log"
	"os"
	"unsafe"
  "time" 
	"math/rand"
	"bufio"
  "strconv"
)

type node struct {
  name string
  children []node
}


type Ebr struct{
	Ebr_Start uint64
	Ebr_Size uint64
	Ebr_Next uint64
	Ebr_Name [16]byte

}
// Struct particion
type partition struct { //3
	Status byte
	PartType byte
	Fit byte
	Start uint64
	Size uint64
	Name [16] byte
}
type MasterBootRecord struct{
	Mbr_Tamanio uint64
	Mbr_fecha [21]byte
	Mbr_IdDisk uint64
	Mbr_Particiones[4] partition

}
type MountParticion struct{
	Mountp_Name [50]byte
	Mountp_Id [6]byte
}


var signatures [100]uint8
// Struct MBR
type mbr struct { 
	Size uint64
	Date [21]byte
	DiskSignature uint8
	Part1 partition
	Part2 partition
	Part3 partition
  Part4 partition
}

var size_ string
var path_ string
var name_ string
var unit_ string



func (n node) String() string {
  buf := new(bytes.Buffer)
  n.print(buf, " ")
  return buf.String()
}

func (n node) print(out io.Writer, indent string) {
  fmt.Fprintf(out, "\n%v%v", indent, n.name)
  for _, nn := range n.children { nn.print(out, indent + "  ") }
}

func Node(name string) node { return node{name: name} }
func (n node) append(nn...node) node { n.children = append(n.children, nn...); return n }

func Pruebas() string {
  s := fmt.Sprintln("hola mundo")
	return s
}





%}

%union{
    node node
    token string
}

//DEFINIMOS LO QUE QUEREMOS QUE ACEPTE NUESTRO ANALIZADOR TERMINALES
%token INT STRING IDENT EXEC PATH DIR ARCHIVO MKDISK SIZE INT MAYOR RUTA RMDISK FDISK NAME DIGIT UNIT
//AQUI LO QUE HACEMOS ES GUARDAR EL VALOR  TERMINALES
%type <token> INT STRING IDENT DIGIT DIR MKDISK NAME ARCHIVO UNIT
//NO TERMINALES 
%type <node> Input  Accion Atributos Parameter

%%
//Gramatica del proyecto
Input: /* empty */ { }
     | Input Accion //{fmt.Println($2)}
     ;

Accion: MKDISK Parameter {createDisk(size_,path_,name_,unit_)}
      | RMDISK Parameter {fmt.Println($2)}
      //| FDISk     {$$ = Node("accion 3")}
     ;

Parameter: Parameter Atributos
         |Atributos
         ;


Atributos: '-'SIZE '-''>' DIGIT  {size_ = $5}
         | '-'PATH '-''>' DIR {path_ = $5}
         | '-'NAME '-''>' ARCHIVO {name_ = $5}
         | '-'UNIT '-''>' IDENT {unit_ = $5} 
        ;


//DIGAMOS AQUI LO QUE HACEMOS ES QUE TIENE QUE RECONOCER int InT, FlOat, CHAR,Char, no importa porque en el .l le agrege opcion de case insentive 
 //   |  FLOAT ';' {$$ = Node($1).append(Node("Reservada"))} //append sirve para concatenar mas valores
//    |  CHAR ';' {$$ = Node($1)}



%% 


func Execute() {
	fi := bufio.NewReader(os.NewFile(0, "stdin"))
	yyDebug = 0
	yyErrorVerbose = true
	for {
		var eqn string
		var ok bool

		fmt.Printf("Ingrese el comando: ")
		if eqn, ok = readline(fi); ok {
			l := newLexer(bytes.NewBufferString(eqn), os.Stdout, "file.name")
			yyParse(l)
		} else {
			break
		}
	}

}


func readline(fi *bufio.Reader) (string, bool) {
	s, err := fi.ReadString('\n')
	if err != nil {
		return "", false
	}
	return s, true
}





func readFile(archivo string)mbr {
	file, err := os.Open(archivo)
	defer file.Close()
	if err != nil{
		log.Fatal(err)
	}
	m :=mbr{}
	var size int = int(unsafe.Sizeof(m))
	fmt.Println("tamanio de mbr ", size)
	data := readNextBytes(file, size)
	fmt.Println("imprimo data", data)
	buffer := bytes.NewBuffer(data)
	err = binary.Read(buffer, binary.BigEndian, &m)
	if err !=nil{
		log.Fatal("binary.Read failed", err)
	}
return m	


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

func getDate() [21]byte { //devuelvo en byte la fecha de una vez
var char [21]byte
t := time.Now()
fecha := fmt.Sprintf("%d-%02d-%02dT%02d:%02d:%02d",
	t.Year(), t.Month(), t.Day(),
	t.Hour(), t.Minute(), t.Second())
fmt.Println("fecha creada  es =>", fecha)
copy(char[:], fecha)
return char
}

func createDisk(size_ string,path_ string,name_ string,unit_ string){

numero_size, error:= strconv.Atoi(size_)
if error !=nil{
  fmt.Println("Error al convervir string a int ", error)
}


	file, err := os.Create(name_)
	defer file.Close()
	if err != nil{
		log.Fatal(err)
	}
  

  x := int64(numero_size *1024)
if unit_ == "k"{
    x =int64(numero_size *1024)
}else if unit_ == "m"{
    x =int64(numero_size *1024*1024)
}

	mbr := createMBR(uint64(x))
	s := &mbr
	_,err = file.Seek(x-1, 0)
	if err != nil {
	log.Fatal("failed to seek")
	}
	_,err = file.Write([]byte {0})
	if err != nil {
	log.Fatal("Write filed")
	}
	file.Seek(0, 0) 
	

	
	var binario2 bytes.Buffer
	binary.Write(&binario2, binary.BigEndian, s)
	writeNextBytes(file, binario2.Bytes())

	var binario bytes.Buffer
	var n uint8
	file.Seek(x, int(unsafe.Sizeof(mbr)))
	binary.Write(&binario, binary.BigEndian, n)
	writeNextBytes(file, binario.Bytes())







}


func writeNextBytes(file *os.File, bytes []byte) {

	_, err := file.Write(bytes)

	if err != nil {
		log.Fatal(err)
	}

}


func createMBR(x uint64) mbr{


  
	mbr:=mbr{}
	mbr.Size = x //size disco
	var c [21]byte
	c =getDate()//fecha
	copy(mbr.Date[:], c[:])
	//disk?signatura
	mbr.DiskSignature = randomNum()

	//part1
	name := "Part1"
	var nameParameter [16]byte
	copy(nameParameter[:], name)
	var inicio uint64
	inicio=uint64(unsafe.Sizeof(mbr))
	mbr.Part1 = mbrPartition('0', 'P','W', inicio, inicio, nameParameter)//part2
	name= "Part2"
	copy(nameParameter[:], name)
	mbr.Part2 = mbrPartition('0', 'P','W', inicio, inicio, nameParameter)	//part3
	name= "Part3"
	copy(nameParameter[:], name)
	mbr.Part3 = mbrPartition('0', 'P','W', inicio, inicio, nameParameter)	//part4	
		name= "Part4"
	copy(nameParameter[:], name)
	mbr.Part4 = mbrPartition('0', 'P','W', inicio, inicio, nameParameter)
 return mbr
}

func createPartition(){
  //part1
	//name := "Part1"
	//var nameParameter [16]byte
	//copy(nameParameter[:], name)
	//var inicio uint64
	//inicio=uint64(unsafe.Sizeof(mbr))
	//mbr.Part1 = mbrPartition('0', 'P','W', inicio, 20000, nameParameter)
}



func mbrPartition(status byte, tipo byte, fit byte, start uint64,size uint64, name [16]byte)partition{
partition := partition{}
partition.Status = status
partition.PartType = tipo
partition.Fit = fit 
partition.Start = start
partition.Size = size
partition.Name = name 
return partition
}

func readNextBytes(file *os.File, number int)[]byte{
	bytes:= make([]byte, number)
	_, err :=file.Read(bytes)
	if err !=nil{
		log.Fatal(err)
	}
	return bytes
}


func pausa_(){
  fmt.Println("Estamos en Pausa ...")
	bufio.NewReader(os.Stdin).ReadBytes('\n')
}
func eliminar_disco(path_ string){
  err := os.Remove(path_)
	if err != nil {
		log.Fatal(err)
	}
}