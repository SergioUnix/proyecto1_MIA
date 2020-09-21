%{
// Copyright (c) 2015 The golex Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// This is an example program using golex run time library.
package sergio_parser

import (
  "bufio"
  "go/token"
  "io"
	"unicode"

	"modernc.org/golex/lex"
)

// Allocate Character classes anywhere in [0x80, 0xFF].
const (
	classUnicodeLeter = iota + 0x80
	classUnicodeDigit
	classOther
)

type lexer struct {
	*lex.Lexer
}

func rune2Class(r rune) int {
	if r >= 0 && r < 0x80 { // Keep ASCII as it is.
		return int(r)
	}
	if unicode.IsLetter(r) {
		return classUnicodeLeter
	}
	if unicode.IsDigit(r) {
		return classUnicodeDigit
	}
	return classOther
}

func newLexer(src io.Reader, dst io.Writer, fName string) *lexer {
  file := token.NewFileSet().AddFile(fName, -1, 1<<31-1)
  lx, err := lex.New(file, bufio.NewReader(src), lex.RuneClass(rune2Class))
  if (err != nil) { panic(err) }
  return &lexer{lx}
}

func (l *lexer) Lex(lval *yySymType) int {
  c := l.Enter()

%}
%option case-insensitive
%yyc c
%yyn c = l.Next()
%yym l.Mark()
dir           [/]{letter}+([/]{letter}*)*[/]{archivo}*|(\"[^"]*\")    
digit         [0-9]+|{unicodeDigit}+ //AQUI VOS YA SABES COMO FUNCIONAN  son EXPRESIONES REGULARES LO DEMAS DE ARRIba QUEDA IGUAL XD 
archivo       {letter}({letter}|{digit})*[.]{letter}+
identifier    {letter}({letter}|{digit})*
letter        [_a-zA-Z]|{unicodeLetter}
linea          \\\*\n
	
unicodeDigit  \x81 //ESTO ES PORQUE GO TRABAJA CON UTF-8 POR ESO ES NECESARIO 
unicodeLetter \x80
%%
	c = l.Rule0()

[ \t\r\n]+
exec lval.token = string(l.TokenBytes(nil)); return EXEC
path lval.token = string(l.TokenBytes(nil)); return PATH //
{dir} lval.token = string(l.TokenBytes(nil)); return DIR
mkdisk lval.token = string(l.TokenBytes(nil)); return MKDISK
rmdisk lval.token = string(l.TokenBytes(nil)); return RMDISK
size lval.token = string(l.TokenBytes(nil)); return SIZE
fdisk lval.token = string(l.TokenBytes(nil)); return FDISK
name lval.token = string(l.TokenBytes(nil)); return NAME
unit lval.token = string(l.TokenBytes(nil)); return UNIT
{linea}  lval.token = string(l.TokenBytes(nil)); return LINEA 
{archivo} lval.token = string(l.TokenBytes(nil)); return ARCHIVO
int  lval.token = string(l.TokenBytes(nil)); return INT  //mira pues aqui es lo importante digamos ahi puse int al principio y es lo que tiene que reconocer si pongo digamos intt solo eso va hagarrar y el return sirve para devolver el token que definimos en el .y //{archivo} lval.token = string(l.TokenBytes(nil)); return ARCHIVO
string lval.token = string(l.TokenBytes(nil)); return STRING
{digit} lval.token = string(l.TokenBytes(nil)); return DIGIT
{identifier} lval.token = string(l.TokenBytes(nil)); return IDENT //cuando definis expresiones regulares tienen que ir dentro de llaves para que las reconozca, de preferencia ponelo de ultimo para que no te de problema con los valores, asi como los que estan arriba de ella 
%%
	if c, ok := l.Abort(); ok { return int(c) }
	goto yyAction
}