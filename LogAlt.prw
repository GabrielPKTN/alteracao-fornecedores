#INCLUDE "TBICONN.CH"
#INCLUDE "PROTHEUS.CH"
/*--------------------------------------------------------------------------------±±
±± Programa  | LogAlt | Autor | Henrique Freitas Alves | Data | 15/09/2023        ±±
±±--------------------------------------------------------------------------------±±
±± Descricao | Grava o log de alterações do protheus.                             ±±
±±--------------------------------------------------------------------------------±±
±± Parametros| Nil => Nenhum                                                      ±±
±±--------------------------------------------------------------------------------±±
±± Retorno   | Nil => Nenhum                                                      ±±
±±--------------------------------------------------------------------------------±±
±± Analista Resp.|  Data  | Manutencao Efetuada                                   ±±
±±--------------------------------------------------------------------------------±±
±±               |  /  /  |CH XXXXX -                                             ±±
±±--------------------------------------------------------------------------------*/
/*/{Protheus.doc} LogAlt
Grava o log de alterações do protheus na tabela TBL_LOG_ALTERACAO_PROTHEUS.
@type function
@version 1.0
@author Henrique Freitas Alves
@since 15/09/2023
@param [c_Tabela], character, A tabela que está sendo alterado.
@param [n_Recno], numeric, O número do registro que está sendo alterado.
@param [c_Campos], character, O(s) campo(s) que foram alterados.
@param [x_De], variant, O valor inicial do campo que está sendo alterado.
@param [x_Para], variant, O valor final do campo que está sendo alterado.
@param [d_Quando], date, A data de quando ocorreu a alteração.
@param [c_Quem], character, Quem foi o responsável pela alteração.
@param [c_Origem], character, A origem da alteração.
@param [c_Obs], character, A observação da alteração.
/*/
User Function LogAlt(c_Tabela, n_Recno, c_Campos, x_De, x_Para, d_Quando, c_Quem, c_Origem, c_Obs)

Local a_Area    := FWGetArea()
Local c_Error   := ""
Local c_Insert  := ""
Local c_Quando  := ""
Local l_Ret     := .T.

Default c_Origem := FunName()
Default c_Quem   := cUserName
Default c_Obs    := ""
Default d_Quando := DATE()

c_Quando := DToS(d_Quando)+" "+Time()

//Se a tabela não existir, crio na hora
If ( !TcCanOpen("TBL_LOG_ALTERACAO_PROTHEUS") )

    c_Error := CriaTabela()
    l_Ret := Empty(c_Error)
EndIf 

If ( l_Ret )

    If ( ValType(x_De) == "N" )
        x_De := CValToChar(x_De)
    ElseIf ( ValType(x_De) == "D" )
        x_De := DToS(x_De)
    EndIf 

    If ( ValType(x_Para) == "N" )
        x_Para := CValToChar(x_Para)
    ElseIf ( ValType(x_Para) == "D" )
        x_Para := DToS(x_Para)
    EndIf 

    c_Insert := "INSERT INTO TBL_LOG_ALTERACAO_PROTHEUS (TABELA, "+IIF(Empty(n_Recno), "", "RECNO,")+" CAMPO, DE, PARA, QUANDO, QUEM, ORIGEM, OBS)"+CRLF
    c_Insert += "VALUES ('"+c_Tabela+"', "+IIF(Empty(n_Recno), "", CValToChar(n_Recno)+",")+" '"+c_Campos+"',  '"+x_De+"', '"+x_Para+"', CAST('"+c_Quando+"' AS DATETIME), '"+c_Quem+"', '"+c_Origem+"', '"+c_Obs+"')" 

    If ( "DROP" $ c_Insert )
        U_FCConOut("Tentativa de injection SQL!"+CRLF+"Origem:"+c_Origem+CRLF+"Usuário: "+c_Quem, "FATAL")
        l_Ret := .F.
    ElseIf ( "TRUNCATE" $ c_Insert )
        U_FCConOut("Tentativa de injection SQL!"+CRLF+"Origem:"+c_Origem+CRLF+"Usuário: "+c_Quem, "FATAL")
        l_Ret := .F.
    ElseIf ( "UPDATE" $ c_Insert )
        U_FCConOut("Tentativa de injection SQL!"+CRLF+"Origem:"+c_Origem+CRLF+"Usuário: "+c_Quem, "FATAL")
        l_Ret := .F.
    ElseIf ( "INSERT INTO " $ SubStr(c_Insert, 39) )
        U_FCConOut("Tentativa de injection SQL!"+CRLF+"Origem:"+c_Origem+CRLF+"Ususário: "+c_Quem, "FATAL")
        l_Ret := .F.
    Else 
        TcSqlExec(c_Insert)
        c_Error := TcSqlError()

        If ( !Empty(c_Error) )
            U_FCConOut("LOG não foi gravado!"+CRLF+"Origem:"+c_Origem+CRLF+"Usuário: "+c_Quem+CRLF+"Erro:"+c_Error, "ERROR")
            l_Ret := .T.
        EndIf 
    EndIf 
Else 
    U_FCConOut("Não foi possível seguir com a gravação do LOG. Houveram erros na criação da tabela!"+CRLF+"Erro:"+c_Error, "ERROR")
EndIf 

FWRestArea(a_Area)

Return Nil
/*/{Protheus.doc} CriaTabela
Faço a criação da tabela TBL_LOG_ALTERACAO_PROTHEUS caso ela não exista.
@type function
@version 1.0
@author Henrique Freitas Alves
@since 15/09/2023
@return character, c_Error => Mensagem de erro do programa TcSqlExec(). Obtida através do TcSqlError().
/*/
Static Function CriaTabela()

Local c_Query   := ""
Local c_Error   := ""

c_Query += "CREATE TABLE [dbo].[TBL_LOG_ALTERACAO_PROTHEUS]("+CRLF
c_Query += "	[ID]        [bigint] IDENTITY(1,1) NOT NULL,"+CRLF
c_Query += "	[TABELA]    [varchar](10)          NOT NULL,"+CRLF
c_Query += "	[RECNO]     [float]                    NULL,"+CRLF
c_Query += "	[CAMPO]     [varchar](50)          NOT NULL,"+CRLF
c_Query += "	[DE]        [varchar](255)         NOT NULL,"+CRLF
c_Query += "	[PARA]      [varchar](255)         NOT NULL,"+CRLF
c_Query += "	[QUANDO]    [datetime]             NOT NULL,"+CRLF
c_Query += "	[QUEM]      [varchar](50)          NOT NULL,"+CRLF
c_Query += "	[ORIGEM]    [varchar](50)          NOT NULL,"+CRLF
c_Query += "	[OBS]       [varchar](255)         NOT NULL,"+CRLF
c_Query += " CONSTRAINT [PK_TBL_LOG_ALTERACAO_PROTHEUS] PRIMARY KEY CLUSTERED "+CRLF
c_Query += "("+CRLF
c_Query += "	[ID] ASC"+CRLF
c_Query += ")WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]"+CRLF
c_Query += ") ON [PRIMARY]"+CRLF

TcSqlExec(c_Query)

c_Error := TcSqlError()

Return ( c_Error )
