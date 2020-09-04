%{
package sergio_parser

import (
  "fmt"
  "bytes"
  "io"
  "bufio"
	"os"
)

type node struct {
  name string
  children []node
}

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

Accion: MKDISK Parameter {fmt.Println($2)}
      | RMDISK Parameter {fmt.Println($2)}
      //| FDISk     {$$ = Node("accion 3")}
     ;

Parameter: Parameter Atributos
         |Atributos
         ;


Atributos: '-'SIZE '-''>' DIGIT  {$$ = Node($5)}
         | '-'PATH '-''>' DIR {$$ = Node($5)}
         | '-'NAME '-''>' ARCHIVO {$$ = Node($5)}
         | '-'UNIT '-''>' IDENT {$$ = Node($5)} 
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

