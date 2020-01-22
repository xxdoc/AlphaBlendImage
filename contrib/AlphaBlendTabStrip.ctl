VERSION 5.00
Begin VB.UserControl AlphaBlendTabStrip 
   BackStyle       =   0  'Transparent
   CanGetFocus     =   0   'False
   ClientHeight    =   2880
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   5700
   ClipBehavior    =   0  'None
   ScaleHeight     =   2880
   ScaleWidth      =   5700
   Windowless      =   -1  'True
   Begin Project1.AlphaBlendLabel labTab 
      Height          =   348
      Index           =   0
      Left            =   0
      Top             =   0
      Visible         =   0   'False
      Width           =   1020
      _ExtentX        =   1799
      _ExtentY        =   614
      Caption         =   "Tab"
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "Segoe UI"
         Size            =   9
         Charset         =   204
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeOpacity     =   0.75
   End
   Begin Project1.AlphaBlendLabel labBackgr 
      Height          =   390
      Left            =   0
      Top             =   0
      Width           =   4968
      _ExtentX        =   8763
      _ExtentY        =   699
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "Segoe UI"
         Size            =   9
         Charset         =   204
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      BackColor       =   -2147483643
      BackOpacity     =   0.75
   End
End
Attribute VB_Name = "AlphaBlendTabStrip"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'=========================================================================
'
' AlphaBlendTabStrip (c) 2020 by wqweto@gmail.com
'
' Poor Man's TabStrip Control
'
'=========================================================================
Option Explicit
DefObj A-Z
Private Const STR_MODULE_NAME As String = "AlphaBlendTabStrip"

'=========================================================================
' Events
'=========================================================================

Event Click()
Event BeforeClick(TabIndex As Long, Cancel As Boolean)

'=========================================================================
' API
'=========================================================================

Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (lpDst As Any, lpSrc As Any, ByVal ByteLength As Long)
Private Declare Function OleTranslateColor Lib "oleaut32" (ByVal lOleColor As Long, ByVal lHPalette As Long, ByVal lColorRef As Long) As Long
'--- GDI+
Private Declare Function GdipCreateSolidFill Lib "gdiplus" (ByVal argb As Long, hBrush As Long) As Long
Private Declare Function GdipSetSolidFillColor Lib "gdiplus" (ByVal hBrush As Long, ByVal argb As Long) As Long
Private Declare Function GdipFillRectangleI Lib "gdiplus" (ByVal hGraphics As Long, ByVal hBrush As Long, ByVal lX As Long, ByVal lY As Long, ByVal lWidth As Long, ByVal lHeight As Long) As Long
Private Declare Function GdipDeleteBrush Lib "gdiplus" (ByVal hBrush As Long) As Long

'=========================================================================
' Constants and member variables
'=========================================================================

Private m_aTabCaptions()        As String
Private m_oFont                 As StdFont
Private m_oFontBold             As StdFont
Private m_lCurrentTab           As Long

Private Type UcsRgbQuad
    R                   As Byte
    G                   As Byte
    B                   As Byte
    A                   As Byte
End Type

'=========================================================================
' Error handling
'=========================================================================

Private Function PrintError(sFunction As String) As VbMsgBoxResult
    Debug.Print "Critical error: " & Err.Description & " [" & STR_MODULE_NAME & "." & sFunction & "]", Timer
End Function

'=========================================================================
' Properties
'=========================================================================

Property Get Layout() As String
Attribute Layout.VB_UserMemId = -518
    Layout = Join(m_aTabCaptions, "|")
End Property

Property Let Layout(sValue As String)
    m_aTabCaptions = Split(sValue, "|")
    pvLoadTabs
    CurrentTab = CurrentTab
    PropertyChanged
End Property

Property Get Font() As StdFont
    Set Font = m_oFont
End Property

Property Set Font(oValue As StdFont)
    If Not oValue Is Nothing Then
        Set m_oFont = oValue
    Else
        Set m_oFont = New StdFont
    End If
    Set m_oFontBold = pvCloneFont(m_oFont)
    m_oFontBold.Bold = True
    pvResizeTabs
    PropertyChanged
End Property

Property Get CurrentTab() As Long
    CurrentTab = m_lCurrentTab
End Property

Property Let CurrentTab(ByVal lValue As Long)
    m_lCurrentTab = lValue
    If m_lCurrentTab >= labTab.UBound Then
        m_lCurrentTab = labTab.UBound - 1
    ElseIf m_lCurrentTab < 0 Then
        m_lCurrentTab = 0
    End If
    pvResizeTabs
    PropertyChanged
End Property

Property Get TabCaption(ByVal Index As Long) As String
    TabCaption = m_aTabCaptions(Index)
End Property

Property Let TabCaption(ByVal Index As Long, sValue As String)
    m_aTabCaptions(Index) = sValue
    pvResizeTabs
End Property

'=========================================================================
' Methods
'=========================================================================

Private Sub pvLoadTabs()
    Const FUNC_NAME     As String = "pvLoadTabs"
    Dim lIdx            As Long
    
    On Error GoTo EH
    For lIdx = 0 To UBound(m_aTabCaptions)
        If labTab.UBound < lIdx + 1 Then
            Load labTab(lIdx + 1)
            labTab(lIdx + 1).ZOrder vbBringToFront
            labTab(lIdx + 1).BackColor = vbButtonFace
        End If
    Next
    For lIdx = lIdx + 1 To labTab.UBound
        Unload labTab(lIdx)
    Next
    Exit Sub
EH:
    PrintError FUNC_NAME
End Sub

Private Sub pvResizeTabs()
    Const FUNC_NAME     As String = "pvResizeTabs"
    Dim lIdx            As Long
    Dim lTop            As Long
    Dim lLeft           As Long
    Dim lHeight         As Long
    
    On Error GoTo EH
    labBackgr.Move 0, 0, ScaleWidth, ScaleHeight
    lTop = labBackgr.Top + 30
    lLeft = labBackgr.Left + 90
    lHeight = labBackgr.Height - 30
    For lIdx = 0 To labTab.UBound - 1
        With labTab(lIdx + 1)
            .Visible = False
            .Caption = m_aTabCaptions(lIdx)
            .Move lLeft, lTop
            Set .Font = IIf(lIdx = m_lCurrentTab, m_oFontBold, m_oFont)
            .BackOpacity = IIf(lIdx = m_lCurrentTab, 1, 0)
            .AutoSize = True
            .AutoSize = False
            .Width = .Width + IIf(lIdx = m_lCurrentTab, 240, 180)
            .Height = lHeight
            lLeft = lLeft + .Width
            .Visible = True
        End With
    Next
    Exit Sub
EH:
    PrintError FUNC_NAME
End Sub

Private Function pvCloneFont(pFont As IFont) As StdFont
    If Not pFont Is Nothing Then
        pFont.Clone pvCloneFont
    Else
        Set pvCloneFont = New StdFont
    End If
End Function

Private Function pvTranslateColor(ByVal clrValue As OLE_COLOR, Optional ByVal Alpha As Single = 1) As Long
    Dim uQuad           As UcsRgbQuad
    Dim lTemp           As Long
    
    Call OleTranslateColor(clrValue, 0, VarPtr(uQuad))
    lTemp = uQuad.R
    uQuad.R = uQuad.B
    uQuad.B = lTemp
    lTemp = Alpha * &HFF
    If lTemp > 255 Then
        uQuad.A = 255
    ElseIf lTemp < 0 Then
        uQuad.A = 0
    Else
        uQuad.A = lTemp
    End If
    Call CopyMemory(pvTranslateColor, uQuad, 4)
End Function

'=========================================================================
' Events
'=========================================================================

Private Sub labTab_Click(Index As Integer)
    Const FUNC_NAME     As String = "labTab_Click"
    Dim bCancel         As Boolean
    
    On Error GoTo EH
    RaiseEvent BeforeClick(Index - 1, bCancel)
    If Not bCancel Then
        m_lCurrentTab = Index - 1
        pvResizeTabs
        RaiseEvent Click
    End If
    Exit Sub
EH:
    PrintError FUNC_NAME
End Sub

Private Sub labTab_OwnerDraw(Index As Integer, ByVal hGraphics As Long, ByVal hFont As Long, sCaption As String, lLeft As Long, lTop As Long, lWidth As Long, lHeight As Long)
    Const FUNC_NAME     As String = "labTab_OwnerDraw"
    Dim clrLight        As Long
    
    On Error GoTo EH
    If Index - 1 = m_lCurrentTab Then
        clrLight = pvTranslateColor(vbWindowBackground)
        pvDrawRect hGraphics, 0, 0, lWidth, lHeight - 1, clrLight, clrLight, pvTranslateColor(vbWindowText), pvTranslateColor(vbButtonFace)
        lLeft = lLeft + 1
        lWidth = lWidth - 2
    ElseIf Index <> m_lCurrentTab Then
        pvDrawRect hGraphics, 0, 3, lWidth, lHeight - 8, 0, 0, pvTranslateColor(vbWindowText, 0.5), 0
        lWidth = lWidth - 1
    End If
    lTop = lTop + 1
    lHeight = lHeight - 2
    Exit Sub
EH:
    PrintError FUNC_NAME
End Sub

Private Sub labBackgr_OwnerDraw(ByVal hGraphics As Long, ByVal hFont As Long, sCaption As String, lLeft As Long, lTop As Long, lWidth As Long, lHeight As Long)
    Const FUNC_NAME     As String = "labBackgr_OwnerDraw"
    Dim clrDark         As Long
    
    On Error GoTo EH
    clrDark = pvTranslateColor(vbWindowText, 0.25)
    pvDrawRect hGraphics, 0, 0, lWidth, lHeight, clrDark, clrDark, clrDark, pvTranslateColor(vbWindowBackground)
    lLeft = lLeft + 1
    lTop = lTop + 1
    lWidth = lWidth - 2
    lHeight = lHeight - 1
    Exit Sub
EH:
    PrintError FUNC_NAME
End Sub

Private Function pvDrawRect(ByVal hGraphics As Long, _
            ByVal lLeft As Long, ByVal lTop As Long, ByVal lWidth As Long, ByVal lHeight As Long, _
            ByVal clrLeft As Long, ByVal clrTop As Long, ByVal clrRight As Long, ByVal clrBottom As Long) As Boolean
    Const FUNC_NAME     As String = "pvDrawRect"
    Dim hBrush          As Long
    
    On Error GoTo EH
    If GdipCreateSolidFill(clrLeft, hBrush) <> 0 Then
        GoTo QH
    End If
    If GdipFillRectangleI(hGraphics, hBrush, lLeft, lTop, 1, lHeight) <> 0 Then
        GoTo QH
    End If
    If GdipSetSolidFillColor(hBrush, clrTop) <> 0 Then
        GoTo QH
    End If
    If GdipFillRectangleI(hGraphics, hBrush, lLeft + 1, lTop, lWidth, 1) <> 0 Then
        GoTo QH
    End If
    If GdipSetSolidFillColor(hBrush, clrRight) <> 0 Then
        GoTo QH
    End If
    If GdipFillRectangleI(hGraphics, hBrush, lLeft + lWidth - 1, lTop + 1, 1, lHeight) <> 0 Then
        GoTo QH
    End If
    If GdipSetSolidFillColor(hBrush, clrBottom) <> 0 Then
        GoTo QH
    End If
    If GdipFillRectangleI(hGraphics, hBrush, lLeft + 1, lTop + lHeight, lWidth - 1, 1) <> 0 Then
        GoTo QH
    End If
    pvDrawRect = True
QH:
    If hBrush <> 0 Then
        Call GdipDeleteBrush(hBrush)
        hBrush = 0
    End If
    Exit Function
EH:
    PrintError FUNC_NAME
    Resume QH
End Function

'=========================================================================
' Base class events
'=========================================================================

Private Sub UserControl_HitTest(X As Single, Y As Single, HitResult As Integer)
    HitResult = vbHitResultHit
End Sub

Private Sub UserControl_Resize()
    pvResizeTabs
End Sub

Private Sub UserControl_InitProperties()
    Const FUNC_NAME     As String = "UserControl_InitProperties"
    
    On Error GoTo EH
    Set Font = Ambient.Font
    Layout = Ambient.DisplayName
    Exit Sub
EH:
    PrintError FUNC_NAME
End Sub

Private Sub UserControl_ReadProperties(PropBag As PropertyBag)
    Const FUNC_NAME     As String = "UserControl_ReadProperties"
    
    On Error GoTo EH
    With PropBag
        Set Font = .ReadProperty("Font", Ambient.Font)
        Layout = .ReadProperty("Layout", vbNullString)
        CurrentTab = .ReadProperty("CurrentTab", 0)
    End With
    Exit Sub
EH:
    PrintError FUNC_NAME
End Sub

Private Sub UserControl_WriteProperties(PropBag As PropertyBag)
    Const FUNC_NAME     As String = "UserControl_WriteProperties"
    
    On Error GoTo EH
    With PropBag
        .WriteProperty "Font", Font, Ambient.Font
        .WriteProperty "Layout", Layout, vbNullString
        .WriteProperty "CurrentTab", CurrentTab, 0
    End With
    Exit Sub
EH:
    PrintError FUNC_NAME
End Sub
