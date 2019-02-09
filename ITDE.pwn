#include <a_samp>
#include <strlib>		
#include <izcmd>		
#include <foreach>
#include <easyDialog>
#include <dini2>
//#include <YSI_Coding\y_iterate>			


#if !defined isnull 
	#define isnull(%0) ((%0[(%0[0])=='\1'])=='\0')
#endif	 


// ------------------------------------------------------------------------------

// 	Requirements for compiling this filterscript:

//	github.com/oscar-broman/strlib
//  github.com/YashasSamaga/I-ZCMD
// 	github.com/karimcambridge/SAMP-foreach
//  forum.sa-mp.com/attachment.php?attachmentid=11048&d=1511057828
//  github.com/Agneese-Saini/SA-MP/blob/master/pawno/include/dini2.inc
// 	github.com/pawn-lang/compiler/releases

// ------------------------------------------------------------------------------


const TEXT_DRAWS = 3;
const ITDE_DELAY = 50;



static enum 
{
	STEP_NONE,
	STEP_POSITION,
	STEP_TEXT_SIZE,
	STEP_LETTER_SIZE
}



static enum E_TEXT_DRAW_DATA
{
	Type,
	Text:Textid,
	Text[1024],
	Float:PosX,
	Float:PosY,
	Float:TextSizeX,
	Float:TextSizeY,
	Float:LetterSizeX,
	Float:LetterSizeY,
	Font,
	Color,
	BoxColor,
	BackColor,
	UseBox,
	Outline,
	Shadow,
	Alignment,
	Proportional,
	Selectable,
	PreviewModel,
	Float:PreviewRotX,
	Float:PreviewRotY,
	Float:PreviewRotZ,
	Float:PreviewZoom
}

static Textdraw[TEXT_DRAWS][E_TEXT_DRAW_DATA];
static Iterator:Textdraws<TEXT_DRAWS>;


static ITDE_Timer = -1;
static ITDE_Player = INVALID_PLAYER_ID;
static ITDE_Project[28];
static ITDE_Editing = -1;
static ITDE_EditStep;
static ITDE_List[TEXT_DRAWS] = {-1, ...};
static ITDE_ListCount;
static bool:ITDE_ValidProject;


// ------------------------------------------------------------------------------
// FUNCTIONS
// ------------------------------------------------------------------------------


static CreateTextdraw(type, Float:x, Float:y, string[])
{
	if(ITDE_Timer != -1)
	{
		KillTimer(ITDE_Timer);
		ITDE_Timer = -1;
	}

	new id;
	if((id = Iter_Free(Textdraws)) > -1)
	{
		new Text:textid = TextDrawCreate(x, y, string);

		if(textid == Text:INVALID_TEXT_DRAW)
		{	
			printf("\7[ITDE]: Creation | SA-MP Textdraws reached your limit of %d.", MAX_TEXT_DRAWS);
			return -1;
		}

		Textdraw[id][Text][0] = EOS;
		strcat(Textdraw[id][Text], string, 1024);

		Textdraw[id][Type] = type;
		Textdraw[id][Textid] = textid;
		Textdraw[id][PosX] = x;
		Textdraw[id][PosY] = y;
		Textdraw[id][TextSizeX] = 30.0;
		Textdraw[id][TextSizeY] = 30.0;
		Textdraw[id][LetterSizeX] = 0.48;
		Textdraw[id][LetterSizeY] = 1.12;
		Textdraw[id][Font] = 1;
		Textdraw[id][Color] = 0xE1E1E1FF;
		Textdraw[id][BoxColor] = 0x80808080;
		Textdraw[id][BackColor] = 0x000000FF;
		Textdraw[id][UseBox] = 0;
		Textdraw[id][Outline] = 0;
		Textdraw[id][Shadow] = 2;
		Textdraw[id][Alignment] = 0;
		Textdraw[id][Proportional] = 1;
		Textdraw[id][Selectable] = 0;

		TextDrawShowForPlayer(ITDE_Player, textid);

		Iter_Add(Textdraws, id);
		return id;
	}

	printf("\7[ITDE]: Creation | ITDE Textdraws reached your limit of %d.", TEXT_DRAWS);
	return -1;
}


static SetTextdrawPosition(id, Float:x, Float:y)
{	
	TextDrawDestroy(Textdraw[id][Textid]);

	Textdraw[id][Textid] = TextDrawCreate(x, y, Textdraw[id][Text]);
	TextDrawTextSize(Textdraw[id][Textid], Textdraw[id][TextSizeX], Textdraw[id][TextSizeY]);
	TextDrawLetterSize(Textdraw[id][Textid], Textdraw[id][LetterSizeX], Textdraw[id][LetterSizeY]);
	TextDrawFont(Textdraw[id][Textid], Textdraw[id][Font]);
	TextDrawColor(Textdraw[id][Textid], Textdraw[id][Color]);
	TextDrawBoxColor(Textdraw[id][Textid], Textdraw[id][BoxColor]);
	TextDrawBackgroundColor(Textdraw[id][Textid], Textdraw[id][BackColor]);
	TextDrawUseBox(Textdraw[id][Textid], Textdraw[id][UseBox]);
	TextDrawSetOutline(Textdraw[id][Textid], Textdraw[id][Outline]);
	TextDrawSetShadow(Textdraw[id][Textid], Textdraw[id][Shadow]);
	TextDrawAlignment(Textdraw[id][Textid], Textdraw[id][Alignment]);
	TextDrawSetProportional(Textdraw[id][Textid], Textdraw[id][Proportional]);
	TextDrawSetSelectable(Textdraw[id][Textid], Textdraw[id][Selectable]);
	TextDrawSetPreviewModel(Textdraw[id][Textid], Textdraw[id][PreviewModel]);
	TextDrawSetPreviewRot(Textdraw[id][Textid], Textdraw[id][PreviewRotX], Textdraw[id][PreviewRotY], Textdraw[id][PreviewRotZ], Textdraw[id][PreviewZoom]);

	Textdraw[id][PosX] = x;
	Textdraw[id][PosY] = y;

	TextDrawShowForPlayer(ITDE_Player, Textdraw[id][Textid]);
}


static DuplicateTextdraw(id)
{
	if(!Iter_Contains(Textdraws, id))
		return -1;

	if(ITDE_Timer != -1)
	{
		KillTimer(ITDE_Timer);
		ITDE_Timer = -1;
	}

	new x;
	if((x = Iter_Free(Textdraws)) > -1)
	{
		new Text:textid = TextDrawCreate(Textdraw[id][PosX], Textdraw[id][PosY], Textdraw[id][Text]);

		if(textid == Text:INVALID_TEXT_DRAW)
		{	
			printf("\7[ITDE]: Duplication | SA-MP Textdraws reached your limit of %d.", MAX_TEXT_DRAWS);
			return -1;
		}

		TextDrawTextSize(textid, Textdraw[id][TextSizeX], Textdraw[id][TextSizeY]);
		TextDrawLetterSize(textid, Textdraw[id][LetterSizeX], Textdraw[id][LetterSizeY]);
		TextDrawFont(textid, Textdraw[id][Font]);
		TextDrawColor(textid, Textdraw[id][Color]);
		TextDrawBoxColor(textid, Textdraw[id][BoxColor]);
		TextDrawBackgroundColor(textid, Textdraw[id][BackColor]);
		TextDrawUseBox(textid, Textdraw[id][UseBox]);
		TextDrawSetOutline(textid, Textdraw[id][Outline]);
		TextDrawSetShadow(textid, Textdraw[id][Shadow]);
		TextDrawAlignment(textid, Textdraw[id][Alignment]);
		TextDrawSetProportional(textid, Textdraw[id][Proportional]);
		TextDrawSetSelectable(textid, Textdraw[id][Selectable]);
		TextDrawSetPreviewModel(textid, Textdraw[id][PreviewModel]);
		TextDrawSetPreviewRot(textid, Textdraw[id][PreviewRotX], Textdraw[id][PreviewRotY], Textdraw[id][PreviewRotZ], Textdraw[id][PreviewZoom]);		

		Textdraw[x][Text][0] = EOS;
		strcat(Textdraw[x][Text], Textdraw[id][Text], 1024);

		Textdraw[x][Type] = Textdraw[id][Type];
		Textdraw[x][Textid] = textid;
		Textdraw[x][PosX] = Textdraw[id][PosX];
		Textdraw[x][PosY] = Textdraw[id][PosY];
		Textdraw[x][TextSizeX] = Textdraw[id][TextSizeX];
		Textdraw[x][TextSizeY] = Textdraw[id][TextSizeY];
		Textdraw[x][LetterSizeX] = Textdraw[id][LetterSizeX];
		Textdraw[x][LetterSizeY] = Textdraw[id][LetterSizeY];
		Textdraw[x][Font] = Textdraw[id][Font];
		Textdraw[x][Color] = Textdraw[id][Color];
		Textdraw[x][BoxColor] = Textdraw[id][BoxColor];
		Textdraw[x][BackColor] = Textdraw[id][BackColor];
		Textdraw[x][UseBox] = Textdraw[id][UseBox];
		Textdraw[x][Outline] = Textdraw[id][Outline];
		Textdraw[x][Shadow] = Textdraw[id][Shadow];
		Textdraw[x][Alignment] = Textdraw[id][Alignment];
		Textdraw[x][Proportional] = Textdraw[id][Proportional];
		Textdraw[x][Selectable] = Textdraw[id][Selectable];
		Textdraw[x][PreviewModel] = Textdraw[id][PreviewModel];
		Textdraw[x][PreviewRotX] = Textdraw[id][PreviewRotX];
		Textdraw[x][PreviewRotY] = Textdraw[id][PreviewRotY];
		Textdraw[x][PreviewRotZ] = Textdraw[id][PreviewRotZ];
		Textdraw[x][PreviewZoom] = Textdraw[id][PreviewZoom];

		TextDrawShowForPlayer(ITDE_Player, textid);

		Iter_Add(Textdraws, x);
		return x;
	}

	printf("\7[ITDE]: Duplication | ITDE Textdraws reached your limit of %d.", TEXT_DRAWS);
	return -1;
}


static DestroyTextdraw(id, &ret)
{
	if(!Iter_Contains(Textdraws, id))
		return;

	if(ITDE_Timer != -1)
	{
		KillTimer(ITDE_Timer);
		ITDE_Timer = -1;
	}

	TextDrawDestroy(Textdraw[id][Textid]);
	Textdraw[id][Textid] = Text:INVALID_TEXT_DRAW;

	new prev;
	if((prev = Iter_Prev(Textdraws, id)) != Iter_Begin(Textdraws))
	{
		ret = prev;
		goto SKIP;
	}

	new next;
	if((next = Iter_Next(Textdraws, id)) != Iter_End(Textdraws))
		ret = next;

	else ret = -1;

	SKIP:
	Iter_Remove(Textdraws, id);
}


static EditorExit()
{
	foreach(new i : Textdraws)
		TextDrawDestroy(Textdraw[i][Textid]);

	Iter_Clear(Textdraws);
	TogglePlayerControllable(ITDE_Player, true);
	ShowPlayerDialog(ITDE_Player, -1, 0, "", "", "", "");

	if(ITDE_Timer != -1)
	{
		KillTimer(ITDE_Timer);
		ITDE_Timer = -1;
	}

	ITDE_Player = INVALID_PLAYER_ID;
	ITDE_Project[0] = EOS;
	ITDE_Editing = -1;
	ITDE_EditStep = STEP_NONE;
	ITDE_ListCount = 0;
	ITDE_ValidProject = false;

	for(new i; i < TEXT_DRAWS; i++)
		ITDE_List[i] = -1;

	return 1;
}


static Dialog_Main(playerid)
{
	if(ITDE_Timer != -1) 
	{
		KillTimer(ITDE_Timer);
		ITDE_Timer = -1;
	}

	ITDE_Editing = -1;
	ITDE_EditStep = STEP_NONE;

	return Dialog_Show(playerid, DIALOG_MAIN, DIALOG_STYLE_LIST, "Injury's Text Draw Editor", "Create Project\nLoad Project", "Select", "Close");	
}


static Dialog_Options(playerid)
{
	return Dialog_Show(playerid, DIALOG_OPTIONS, DIALOG_STYLE_LIST, "Textdraw Options", "-Delete\n-Duplicate\nType\nText\nPosition\nText Size\nLetterSize\nFont\nColor\nBox Color\nBackground Color", "Select", "List");
}


static Dialog_CreateAndTextdrawList(playerid)
{
	if(Iter_Count(Textdraws) == 0)
		return Dialog_CreateTextdraw(playerid);

	static string[27 * TEXT_DRAWS];
	string = "Create New Textdraw";

	ITDE_ListCount = 0;

	foreach(new i : Textdraws)
	{
		if(strlen(Textdraw[i][Text]) > 16)
			format(string, sizeof string, "%s\nText: %.16s...", string, Textdraw[i][Text]);
		else
			format(string, sizeof string, "%s\nText: %s", string, Textdraw[i][Text]);

		ITDE_List[ITDE_ListCount++] = i;
	}

	return Dialog_Show(playerid, CREATE_AND_TEXTDRAW_LIST, DIALOG_STYLE_LIST, "Create & Textdraw List", string, "Select", "Back");
}


static Dialog_CreateTextdraw(playerid)
{
	return Dialog_Show(playerid, CREATE_TEXTDRAW, DIALOG_STYLE_LIST, "Injury's Text Draw Editor", "Create New Textdraw", "Select", "Back");
}



static SaveProject()
{
	if(ITDE_ValidProject)
	{	
		new name[34], File:File;
		strcat(name, ITDE_Project);
		strcat(name, ".itde");

		File = fopen(name, io_write);

		if(File)
		{		
			static string[1213];

			foreach(new i : Textdraws)
			{
				format(string, sizeof string, "Text: %s\r\n", Textdraw[i][Text]);
				fwrite(File, string);

				format(string, sizeof string, "S%d|%.1f|%.1f|%.1f|%.1f|%.1f|%.1f|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%.1f|%.1f|%.1f|%.1fE\r\n\r\n",

				Textdraw[i][Type],
				Textdraw[i][PosX],
				Textdraw[i][PosY],
				Textdraw[i][TextSizeX],
				Textdraw[i][TextSizeY],
				Textdraw[i][LetterSizeX],
				Textdraw[i][LetterSizeY],
				Textdraw[i][Font],
				Textdraw[i][Color],
				Textdraw[i][BoxColor],
				Textdraw[i][BackColor],
				Textdraw[i][UseBox],
				Textdraw[i][Outline],
				Textdraw[i][Shadow],
				Textdraw[i][Alignment],
				Textdraw[i][Proportional],
				Textdraw[i][Selectable],
				Textdraw[i][PreviewModel],
				Textdraw[i][PreviewRotX],
				Textdraw[i][PreviewRotY],
				Textdraw[i][PreviewRotZ],
				Textdraw[i][PreviewZoom]);

				fwrite(File, string);
			}

			fclose(File);
		}

	}
}


static LoadProject()
{
	new filename[34];
	strcat(filename, ITDE_Project);
	strcat(filename, ".itde");

	new File:File = fopen(filename, io_read);

	if(File)
	{
		static string[1225];
		static tmp[278];
		string[0] = tmp[0] = EOS;

		new 
			Output[22][5],
			start,
			end,

			Type,
			Text[1024],
			Float:X,
			Float:Y,
			Float:LX,
			Float:LY,
			Float:TX,
			Float:TY,
			Font,
			Color,
			BoxColor,
			BackColor,
			UseBox,
			Outline,
			Shadow,
			Align,
			Propor,
			Select,
			Prev,
			Float:PrevRX,
			Float:PrevRY,
			Float:PrevRZ,
			Float:PrevZoom;

		while(fread(File, string))
		{
			if(strfind(string, "Text:", true) != -1)
			{
				if((end = strfind(string, "\r", true) != -1)
				{
					strmid(Text, string, 4, end);
				}
			}


			if((start = strfind(string, "S", true)) != -1)
			{
				if((end = strfind(string, "E", true)) != -1)
				{
					strmid(tmp, string, start + 1, end - 1);
					strexplode(tmp, output, "|");

					Type = strval(output[0]);
					PX = floatstr(output[1]);
					PY = floatstr(output[2]);
					TX = floatstr(output[3]);
					TY = floatstr(output[4]);
					LX = floatstr(output[5]);
					LY = floatstr(output[6]);
					Font = strval(output[7]);
					Color = strval(output[8]);
					BoxColor = strval(output[9]);
					BackColor = strval(output[10]);
					UseBox = strval(output[11]);
					Outline = strval(output[12]);
					Shadow = strval(output[13]);
					Align = strval(output[14]);
					Propor = strval(output[15]);
					Select = strval(output[16]);
					Prev = strval(output[17]);
					PrevRX = floatstr(output[18]);
					PrevRY = floatstr(output[19]);
					PrevRZ = floatstr(output[20]);
					PrevZoom = floatstr(output[21]);

					new idx;

					if((idx = Iter_Free(Texdraws)) > -1)
					{						
						new Text:textid = TextDrawCreate(PX, PY, Text);

						if(textid == Text:INVALID_TEXT_DRAW)
						{	
							printf("\7[ITDE]: Creation | SA-MP Textdraws reached your limit of %d.", MAX_TEXT_DRAWS);
							return -1;
						}

						TextDrawTextSize(textid, TX, TY);
						TextDrawLetterSize(textid, LX, LY);
						TextDrawFont(textid, Font);
						TextDrawColor(textid, Color);
						TextDrawBoxColor(textid, BoxColor);
						TextDrawBackgroundColor(textid, BackColor);
						TextDrawUseBox(textid, UseBox);
						TextDrawSetOutline(textid, Outline);
						TextDrawSetShadow(textid, Shadow);
						TextDrawAlignment(textid, Align);
						TextDrawSetProportional(textid, Propor);
						TextDrawSetSelectable(textid, Select);
						TextDrawSetPreviewModel(textid, Prev);
						TextDrawSetPreviewRot(textid, PrevRX, PrevRY, PrevRZ, PrevZoom);		


						Textdraw[id][Text][0] = EOS;
						strcat(Textdraw[id][Text], Text, 1024);

						Textdraw[id][Type] = Type;
						Textdraw[id][Textid] = textid;
						Textdraw[id][PosX] = PX;
						Textdraw[id][PosY] = PY;
						Textdraw[id][TextSizeX] = TX;
						Textdraw[id][TextSizeY] = TY;
						Textdraw[id][LetterSizeX] = LX;
						Textdraw[id][LetterSizeY] = LY;
						Textdraw[id][Font] = Font;
						Textdraw[id][Color] = Color;
						Textdraw[id][BoxColor] = BoxColor;
						Textdraw[id][BackColor] = BackColor;
						Textdraw[id][UseBox] = UseBox;
						Textdraw[id][Outline] = Outline;
						Textdraw[id][Shadow] = Shadow;
						Textdraw[id][Alignment] = Align;
						Textdraw[id][Proportional] = Propor;
						Textdraw[id][Selectable] = Select;
						Textdraw[id][PreviewModel] = Prev;
						Textdraw[id][PreviewRotX] = PrevRX;
						Textdraw[id][PreviewRotY] = PrevRY;
						Textdraw[id][PreviewRotZ] = PrevRZ;
						Textdraw[id][PreviewZoom] = PrevZoom;

						Iter_Add(Textdraws, id);

						TextDrawShowForPlayer(ITDE_Player, textid);						
					}
				}
			}
		}	
		fclose(File);		
}


static ExportProject()
{
	if(ITDE_ValidProject)
	{
		new filename[33];
		new File:File;

		strcat(filename, ITDE_Project);
		strcat(filename, ".txt");

		File = fopen(filename, io_write);
		if(File)
		{
			static string[4000];
			string[0] = EOS;
			
			new List_Player[TEXT_DRAWS];
			new List_Global[TEXT_DRAWS];
			new count[2];
			new i;
			

			foreach(new j : Textdraws)
			{
				if(Textdraw[j][Type]) List_Player[count[1]++] = j;
				else List_Global[count[0]++] = j;
			}

			if(count[0])
			{			
				format(string, sizeof string, "new Text:%s_TD[%i];%s", ITDE_Project, count[0], !count[1] ? ("\r\n\r\n\r\n") : ("\r\n"));
				fwrite(File, string);
			}

			if(count[1])
			{
				format(string, sizeof string, "new PlayerText:%s_PTD[MAX_PLAYERS][%i];\r\n\r\n\r\n", ITDE_Project, count[1]);
				fwrite(File, string);
			}			
				
			for(i = 0; i < count[0]; i++)
			{
				format(string, sizeof string, "%s_TD[%i] = TextDrawCreate(%.1f, %.1f, \"%s\");\r\n", ITDE_Project, i, Textdraw[i][PosX], Textdraw[i][PosY], Textdraw[i][Text]);
				fwrite(File, string);

				format(string, sizeof string, "TextDrawTextSize(%s_TD[%i], %.1f, %.1f);\r\n", ITDE_Project, i, Textdraw[i][TextSizeX], Textdraw[i][TextSizeY]);
				fwrite(File, string);

				if(Textdraw[i][Font] < 4)
				{
					format(string, sizeof string, "TextDrawLetterSize(%s_TD[%i], %.1f, %.1f);\r\n", ITDE_Project, i, Textdraw[i][LetterSizeX], Textdraw[i][LetterSizeY]);
					fwrite(File, string);	
				}

				format(string, sizeof string, "TextDrawFont(%s_TD[%i], %d);\r\n", ITDE_Project, i, Textdraw[i][Font]);
				fwrite(File, string);

				format(string, sizeof string, "TextDrawColor(%s_TD[%i], %d);\r\n", ITDE_Project, i, Textdraw[i][Color]);
				fwrite(File, string);

				if(Textdraw[i][UseBox])
				{
					format(string, sizeof string, "TextDrawBoxColor(%s_TD[%i], %d);\r\n", ITDE_Project, i, Textdraw[i][BoxColor]);
					fwrite(File, string);						
				}

				format(string, sizeof string, "TextDrawBackgroundColor(%s_TD[%i], %d);\r\n", ITDE_Project, i, Textdraw[i][BackColor]);
				fwrite(File, string);

				format(string, sizeof string, "TextDrawUseBox(%s_TD[%i], %d);\r\n", ITDE_Project, i, Textdraw[i][UseBox]);
				fwrite(File, string);

				format(string, sizeof string, "TextDrawSetOutline(%s_TD[%i], %d);\r\n", ITDE_Project, i, Textdraw[i][Outline]);
				fwrite(File, string);

				format(string, sizeof string, "TextDrawSetShadow(%s_TD[%i], %d);\r\n", ITDE_Project, i, Textdraw[i][Shadow]);
				fwrite(File, string);

				format(string, sizeof string, "TextDrawAlignment(%s_TD[%i], %d);\r\n", ITDE_Project, i, Textdraw[i][Alignment]);
				fwrite(File, string);
				
				format(string, sizeof string, "TextDrawSetProportional(%s_TD[%i], %d);\r\n", ITDE_Project, i, Textdraw[i][Proportional]);
				fwrite(File, string);

				format(string, sizeof string, "TextDrawSetSelectable(%s_TD[%i], %d);\r\n", ITDE_Project, i, Textdraw[i][Selectable]);

				if(Textdraw[i][Font] == 5)
				{
					fwrite(File, string);	
					format(string, sizeof string, "TextDrawSetPreviewModel(%s_TD[%i], %d);\r\n", ITDE_Project, i, Textdraw[i][PreviewModel]);
					fwrite(File, string);

					format(string, sizeof string, "TextDrawSetPreviewModel(%s_TD[%i], %1.f, %1.f, %1.f, %1.f);\r\n\r\n\r\n", ITDE_Project, i, Textdraw[i][PreviewRotX], Textdraw[i][PreviewRotY], Textdraw[i][PreviewRotZ], Textdraw[i][PreviewZoom]);
					fwrite(File, string);						
				}
				else 
				{
					strcat(string, "\r\n\r\n\r\n");
					fwrite(File, string);
				}												
			}

			for(i = 0; i < count[1]; i++)
			{
				format(string, sizeof string, "%s_PTD[playerid][%i] = CreatePlayerTextDraw(playerid, %.1f, %.1f, \"%s\");\r\n", ITDE_Project, i, Textdraw[i][PosX], Textdraw[i][PosY], Textdraw[i][Text]);
				fwrite(File, string);

				format(string, sizeof string, "PlayerTextDrawTextSize(playerid, %s_PTD[playerid][%i], %.1f, %.1f);\r\n", ITDE_Project, i,  Textdraw[i][TextSizeX], Textdraw[i][TextSizeY]);
				fwrite(File, string);

				if(Textdraw[i][Font] < 4)
				{
					format(string, sizeof string, "PlayerTextDrawLetterSize(playerid, %s_PTD[playerid][%i], %.1f, %.1f);\r\n", ITDE_Project, i,  Textdraw[i][LetterSizeX], Textdraw[i][LetterSizeY]);
					fwrite(File, string);	
				}

				format(string, sizeof string, "PlayerTextDrawFont(playerid, %s_PTD[playerid][%i], %d);\r\n", ITDE_Project, i,  Textdraw[i][Font]);
				fwrite(File, string);

				format(string, sizeof string, "PlayerTextDrawColor(playerid, %s_PTD[playerid][%i], %d);\r\n", ITDE_Project, i,  Textdraw[i][Color]);
				fwrite(File, string);

				if(Textdraw[i][UseBox])
				{
					format(string, sizeof string, "PlayerTextDrawBoxColor(playerid, %s_PTD[playerid][%i], %d);\r\n", ITDE_Project, i,  Textdraw[i][BoxColor]);
					fwrite(File, string);						
				}

				format(string, sizeof string, "PlayerTextDrawBackgroundColor(playerid, %s_PTD[playerid][%i], %d);\r\n", ITDE_Project, i,  Textdraw[i][BackColor]);
				fwrite(File, string);

				format(string, sizeof string, "PlayerTextDrawUseBox(playerid, %s_PTD[playerid][%i], %d);\r\n", ITDE_Project, i, Textdraw[i][UseBox]);
				fwrite(File, string);

				format(string, sizeof string, "PlayerTextDrawSetOutline(playerid, %s_PTD[playerid][%i], %d);\r\n", ITDE_Project, i, Textdraw[i][Outline]);
				fwrite(File, string);

				format(string, sizeof string, "PlayerTextDrawSetShadow(playerid, %s_PTD[playerid][%i], %d);\r\n", ITDE_Project, i, Textdraw[i][Shadow]);
				fwrite(File, string);

				format(string, sizeof string, "PlayerTextDrawAlignment(playerid, %s_PTD[playerid][%i], %d);\r\n", ITDE_Project, i, Textdraw[i][Alignment]);
				fwrite(File, string);
				
				format(string, sizeof string, "PlayerTextDrawSetProportional(playerid, %s_PTD[playerid][%i], %d);\r\n", ITDE_Project, i, Textdraw[i][Proportional]);
				fwrite(File, string);

				format(string, sizeof string, "PlayerTextDrawSetSelectable(playerid, %s_PTD[playerid][%i], %d);\r\n\r\n", ITDE_Project, i, Textdraw[i][Selectable]);
				fwrite(File, string);

				if(Textdraw[i][Font] == 5)
				{
					fwrite(File, string);
					format(string, sizeof string, "PlayerTextDrawSetPreviewModel(playerid, %s_PTD[playerid][%i], %d);\r\n", ITDE_Project, i, Textdraw[i][PreviewModel]);
					fwrite(File, string);

					format(string, sizeof string, "PlayerTextDrawSetPreviewModel(playerid, %s_PTD[playerid][%i], %1.f, %1.f, %1.f, %1.f);\r\n\r\n", ITDE_Project, i, Textdraw[i][PreviewRotX], Textdraw[i][PreviewRotY], Textdraw[i][PreviewRotZ], Textdraw[i][PreviewZoom]);
					fwrite(File, string);						
				}																																																							
			}				

			fclose(File);								
		}
	}
}	


// ------------------------------------------------------------------------------
// DIALOGS
// ------------------------------------------------------------------------------


DIALOG:CREATE_AND_TEXTDRAW_LIST(playerid, response, listitem, inputtext[])
{
	if(!response)
		return Dialog_Show(playerid, CONTINUE_PROJECT, DIALOG_STYLE_LIST, "Injury's Text Draw Editor", "Continue Current Project\nExport & Close Current Project\nClose Current Project", "Select", "Cancel");

	switch(listitem)
	{
		case 0:
		{
			if((ITDE_Editing = CreateTextdraw(0, 200.0, 150.0, "Textdraw")) != -1) 
			{
				SendClientMessage(playerid, -1, "[ITDE]: New textdraw created.");
				Dialog_Options(playerid);
			}	
			else 
			{
				SendClientMessage(playerid, -1, "[ITDE]: Failed to create textdraw | limits reached.");
			}				
		}

		default: 
		{
			ITDE_Editing = ITDE_List[listitem - 1];	
			Dialog_Options(playerid);
		}
	}
	return 1;
}


DIALOG:CREATE_TEXTDRAW(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		if((ITDE_Editing = CreateTextdraw(0, 290.0, 100.0, "Textdraw")) != -1) 
		{
			SendClientMessage(playerid, -1, "[ITDE]: New textdraw created.");
			Dialog_Options(playerid);
		}	
		else 
		{
			SendClientMessage(playerid, -1, "[ITDE]: Failed to create textdraw | limits reached.");
		}	
	}


	return 1;
}


DIALOG:DIALOG_MAIN(playerid, response, listitem, inputtext[])
{
	if(response)
	{	
		switch(listitem)
		{
			case 0:	Dialog_Show(playerid, SET_PROJECT_NAME, DIALOG_STYLE_INPUT, "Create New project", "Write your project name below", "Set", "Back");
			case 1:
			{
			}

		}
	}
	else 
	{
		EditorExit();
	}

	return 1;
}


DIALOG:SET_TYPE(playerid, response, listitem, inputtext[])
{
	if(!response)
		return Dialog_Options(playerid);

	Textdraw[ITDE_Editing][Type] = listitem;

	new string[51];
	format(string, sizeof string, "[ITDE]: Textdraw type has been setted to \"%s\".", listitem ? ("Player") : ("Global"));
	SendClientMessage(playerid, -1, string);

	Dialog_Options(playerid);	
	return 1;
}


DIALOG:SET_TEXT(playerid, response, listitem, inputtext[])
{
	if(!response)
		return Dialog_Options(playerid);

	Textdraw[ITDE_Editing][Text][0] = EOS;
	strcat(Textdraw[ITDE_Editing][Text], inputtext, 1024);
	TextDrawSetString(Textdraw[ITDE_Editing][Textid], inputtext);

	if(strlen(inputtext) > 20)
	{
		new string[72];
		format(string, sizeof string, "[ITDE]: Textdraw text has been setted to \"%.20s...\".", inputtext);
		SendClientMessage(playerid, -1, string);		
	}
	else 
	{
		new string[64];
		format(string, sizeof string, "[ITDE]: Textdraw text has been setted to \"%s\".", inputtext);
		SendClientMessage(playerid, -1, string);		
	}	

	Dialog_Options(playerid);
	return 1;
}


DIALOG:SET_PROJECT_NAME(playerid, response, listitem, inputtext[])
{
	if(!response)
		return Dialog_Options(playerid);


	new bool:success, len = strlen(inputtext);

	for(new i; i < len; i++) {
		if('a' <= inputtext[i] <= 'z' || 'A' <= inputtext[i] <= 'Z') {
			success = true;
			break;	
		}
	}

	new string[69];
	strcat(string, inputtext);
	strcat(string, ".txt");

	if(dini_Exists(string))
	{
		SendClientMessage(playerid, -1, "[ITDE]: Another project with same name already exists.");
		return Dialog_Show(playerid, SET_PROJECT_NAME, DIALOG_STYLE_INPUT, "Create New project", "Write your project name below", "Set", "Back");
	}	

	if(!success || len > 28)
	{
		SendClientMessage(playerid, -1, "[ITDE]: Your project name must contain from 1 to 28 and alphabet characters.");
		return Dialog_Show(playerid, SET_PROJECT_NAME, DIALOG_STYLE_INPUT, "Create New project", "Write your project name below", "Set", "Back");
	}

	ITDE_Project[0] = EOS;
	strcat(ITDE_Project, inputtext, sizeof ITDE_Project);

	dini_Create(string);
	format(string, sizeof string, "[ITDE]: New project created with name \"%s\"", ITDE_Project);
	SendClientMessage(playerid, -1, string);

	ITDE_ValidProject = true;

	Dialog_CreateTextdraw(playerid);
	return 1;
}


DIALOG:SET_POSITION(playerid, response, listitem, inputtext[])
{
	if(!response)
		return Dialog_Options(playerid);

	if(strfind(inputtext, ",", true) == -1)
	{
		SendClientMessage(playerid, -1, "[ITDE]: Wrong format.");
		return Dialog_Show(playerid, SET_POSITION, DIALOG_STYLE_INPUT, "Set Text Draw Position", "Example: 50.0, 43.0", "Set", "Back");
	}

	new tmp[2][12];
	strexplode(tmp, inputtext, ",");

	SetTextdrawPosition(ITDE_Editing, floatstr(tmp[0]), floatstr(tmp[1]));
	Dialog_Options(playerid);
	return 1;
}


DIALOG:SET_TEXT_SIZE(playerid, response, listitem, inputtext[])
{
	if(!response)
		return Dialog_Options(playerid);

	if(strfind(inputtext, ",", true) == -1)
	{
		SendClientMessage(playerid, -1, "[ITDE]: Wrong format.");
		return Dialog_Show(playerid, SET_TEXT_SIZE, DIALOG_STYLE_INPUT, "Set Text Draw Text Size", "Example: 50.0, 43.0", "Set", "Back");
	}

	new tmp[2][12];
	strexplode(tmp, inputtext, ",");

	new Float:x = floatstr(tmp[0]); 
	new Float:y = floatstr(tmp[1]);

	Textdraw[ITDE_Editing][TextSizeX] = x;
	Textdraw[ITDE_Editing][TextSizeY] = y;

	TextDrawTextSize(Textdraw[ITDE_Editing][Textid], x, y);
	TextDrawShowForPlayer(playerid, Textdraw[ITDE_Editing][Textid]);

	Dialog_Options(playerid);
	return 1;
}


DIALOG:SET_LETTER_SIZE(playerid, response, listitem, inputtext[])
{
	if(!response)
		return Dialog_Options(playerid);

	if(strfind(inputtext, ",", true) == -1)
	{
		SendClientMessage(playerid, -1, "[ITDE]: Wrong format.");
		return Dialog_Show(playerid, SET_LETTER_SIZE, DIALOG_STYLE_INPUT, "Set Text Draw Letter Size", "Example: 50.0, 43.0", "Set", "Back");
	}

	new tmp[2][12];
	strexplode(tmp, inputtext, ",");

	new Float:x = floatstr(tmp[0]); 
	new Float:y = floatstr(tmp[1]);

	Textdraw[ITDE_Editing][LetterSizeX] = x;
	Textdraw[ITDE_Editing][LetterSizeY] = y;
	
	TextDrawLetterSize(Textdraw[ITDE_Editing][Textid], x, y);
	TextDrawShowForPlayer(playerid, Textdraw[ITDE_Editing][Textid]);

	Dialog_Options(playerid);
	return 1;
}


DIALOG:DIALOG_OPTIONS(playerid, response, listitem, inputtext[])
{
	if(!response)
		return Dialog_CreateAndTextdrawList(playerid);


	switch(listitem)
	{
		case 0: 
		{
			DestroyTextdraw(ITDE_Editing, ITDE_Editing);

			if(ITDE_Editing == -1) 
			{
				Dialog_CreateTextdraw(playerid);
			}
			else 
			{
				ITDE_Timer = SetTimer("Timer_ITDE", ITDE_DELAY, true);
			}	

		}
		case 1: 
		{
			if((ITDE_Editing = DuplicateTextdraw(ITDE_Editing)) != -1)	
			{
				SendClientMessage(ITDE_Player, -1, "[ITDE]: Textdraw duplicated.");
				Dialog_Options(playerid);
			}
			else 
			{
				SendClientMessage(ITDE_Player, -1, "[ITDE]: Failed to duplicate textdraw | limits reached.");
				ITDE_Editing = Iter_Last(Textdraws);
			}			
		}	

		case 2:	 Dialog_Show(playerid, SET_TYPE, DIALOG_STYLE_LIST, "Set Text Draw Type", "Global\nPlayer", "Set", "Back");
		case 3:  Dialog_Show(playerid, SET_TEXT, DIALOG_STYLE_INPUT, "Set Text Text", "Write your text draw text below", "Done", "Back");

		case 4:  
		{
			ITDE_EditStep = STEP_POSITION;
			Dialog_Show(playerid, SET_OPTIONS, DIALOG_STYLE_LIST, "Text Draw Modifier Type", "Use Keyboard\nManual Input", "Select", "Back");
		}	

		case 5:  
		{
			ITDE_EditStep = STEP_TEXT_SIZE;
			Dialog_Show(playerid, SET_OPTIONS, DIALOG_STYLE_LIST, "Text Draw Modifier Type", "Use Keyboard\nManual Input", "Select", "Back");
		}
			
		case 6:  
		{

			ITDE_EditStep = STEP_LETTER_SIZE;
			Dialog_Show(playerid, SET_OPTIONS, DIALOG_STYLE_LIST, "Text Draw Modifier Type", "Use Keyboard\nManual Input", "Select", "Back");
		}	
	}

	return 1;
}


DIALOG:SET_OPTIONS(playerid, response, listitem, inputtext[])
{
	if(!response)
		return Dialog_Options(playerid);


	switch(listitem)
	{
		case 0:
		{
			ShowPlayerDialog(playerid, -1, 0, "", "", "", "");

			if(ITDE_Timer != -1)
				KillTimer(ITDE_Timer);

			ITDE_Timer = SetTimer("Timer_ITDE", ITDE_DELAY, true);

			if(STEP_TEXT_SIZE <= ITDE_EditStep <= STEP_LETTER_SIZE)
				SendClientMessage(playerid, -1, "[ITDE]: You can hold \"~k~~PED_JUMPING~\" for scale proportionally.");
		}

		case 1:
		{
			switch(ITDE_EditStep)
			{
				case STEP_POSITION:    Dialog_Show(playerid, SET_POSITION, DIALOG_STYLE_INPUT, "Set Text Draw Position", "Example: 50.0 43.0", "Set", "Back");
				case STEP_TEXT_SIZE:   Dialog_Show(playerid, SET_TEXT_SIZE, DIALOG_STYLE_INPUT, "Set Text Draw Text Size", "Example: 50.0, 43.0", "Set", "Back");	
				case STEP_LETTER_SIZE: Dialog_Show(playerid, SET_LETTER_SIZE, DIALOG_STYLE_INPUT, "Set Text Draw Letter Size", "Example: 50.0, 43.0", "Set", "Back");	
			}

			ITDE_EditStep = STEP_NONE;	
		}		
	}

	return 1;
}


DIALOG:CONTINUE_PROJECT(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		switch(listitem)
		{
			case 0:
			{
				Dialog_CreateAndTextdrawList(playerid);
			}

			case 1:
			{
				if(ITDE_ValidProject)
				{
					SaveProject();
					ExportProject();
					ITDE_Project[0] = EOS;
					ITDE_ValidProject = false;					
				}
			}

			case 2:
			{
				ITDE_Project[0] = EOS;
				ITDE_ValidProject = false;

				SendClientMessage(playerid, -1, "[ITDE]: You have been closed current project.");
			}
		}
	}

	return 1;
}


// ------------------------------------------------------------------------------
// TIMER
// ------------------------------------------------------------------------------


forward Timer_ITDE(); public Timer_ITDE()
{
	if(ITDE_Editing == -1)
		return 1;

	static keys, updown, leftright;
	GetPlayerKeys(ITDE_Player, keys, updown, leftright);

	new direction = -1;
	new Float:tmp = 1.0;

	if(keys & KEY_CROUCH)
	{
		static last_dup;

		if(gettime() > last_dup)
		{
			if((ITDE_Editing = DuplicateTextdraw(ITDE_Editing)) != -1)	
			{
				SendClientMessage(ITDE_Player, -1, "[ITDE]: Textdraw duplicated.");
			}
			else 
			{
				SendClientMessage(ITDE_Player, -1, "[ITDE]: Failed to duplicate textdraw | limits reached.");

				if(Iter_Count(Textdraws) > 0) ITDE_Editing = Iter_Last(Textdraws);
				else return Dialog_CreateTextdraw(ITDE_Player);
			}

			last_dup = gettime();
		}
	}

	else if(keys & KEY_WALK)
		tmp = 0.1;

	else if(keys & KEY_SPRINT)
		tmp = 10.0;


	if(updown < 0) // up
		direction = 0;

	else if(updown > 0) // down
		direction = 1;

	else if(leftright < 0) // left
		direction = 2;

	else if(leftright > 0) //right
		direction = 3;


	if(direction > -1)
	{	
		static string[38];

		switch(ITDE_EditStep)
		{
			case STEP_POSITION:
			{
				switch(direction)
				{
					case 0: Textdraw[ITDE_Editing][PosY] -= tmp;
					case 1: Textdraw[ITDE_Editing][PosY] += tmp;
					case 2: Textdraw[ITDE_Editing][PosX] -= tmp;
					case 3: Textdraw[ITDE_Editing][PosX] += tmp;
				}

				format(string, sizeof string, "~y~X: ~w~%.1f  ~y~Y: ~w~%.1f", Textdraw[ITDE_Editing][PosX], Textdraw[ITDE_Editing][PosY]);
				GameTextForPlayer(ITDE_Player, string, 1000, 5);	

				SetTextdrawPosition(ITDE_Editing, Textdraw[ITDE_Editing][PosX], Textdraw[ITDE_Editing][PosY]);
			}

			case STEP_TEXT_SIZE:
			{
				if(keys & KEY_JUMP)
				{
					switch(direction)
					{					
						case 0:
						{
							Textdraw[ITDE_Editing][TextSizeY] -= tmp;
							Textdraw[ITDE_Editing][TextSizeX] = Textdraw[ITDE_Editing][TextSizeY];
						}

						case 1:
						{
							Textdraw[ITDE_Editing][TextSizeY] += tmp;
							Textdraw[ITDE_Editing][TextSizeX] = Textdraw[ITDE_Editing][TextSizeY];
						}

						case 2:
						{
							Textdraw[ITDE_Editing][TextSizeX] -= tmp;
							Textdraw[ITDE_Editing][TextSizeY] = Textdraw[ITDE_Editing][TextSizeX];
						}

						case 3:
						{
							Textdraw[ITDE_Editing][TextSizeX] += tmp;
							Textdraw[ITDE_Editing][TextSizeY] = Textdraw[ITDE_Editing][TextSizeX];
						}
					}
				}
				else 
				{				
					switch(direction)
					{
						case 0: Textdraw[ITDE_Editing][TextSizeY] -= tmp;
						case 1: Textdraw[ITDE_Editing][TextSizeY] += tmp;
						case 2: Textdraw[ITDE_Editing][TextSizeX] -= tmp;
						case 3: Textdraw[ITDE_Editing][TextSizeX] += tmp;
					}
				}


				format(string, sizeof string, "~y~X: ~w~%.1f  ~y~Y: ~w~%.1f", Textdraw[ITDE_Editing][TextSizeX], Textdraw[ITDE_Editing][TextSizeY]);
				GameTextForPlayer(ITDE_Player, string, 1000, 5);				

				TextDrawTextSize(Textdraw[ITDE_Editing][Textid], Textdraw[ITDE_Editing][TextSizeX], Textdraw[ITDE_Editing][TextSizeY]);
				TextDrawShowForPlayer(ITDE_Player, Textdraw[ITDE_Editing][Textid]);
			}

			case STEP_LETTER_SIZE:
			{
				tmp /= 10.0;

				if(keys & KEY_JUMP)
				{
					switch(direction)
					{
						case 0: 
						{
							Textdraw[ITDE_Editing][LetterSizeY] -= tmp;
							Textdraw[ITDE_Editing][LetterSizeX] = (Textdraw[ITDE_Editing][LetterSizeY] / 4.0);
						}
							
						case 1:
						{
							Textdraw[ITDE_Editing][LetterSizeY] += tmp;
							Textdraw[ITDE_Editing][LetterSizeX] = (Textdraw[ITDE_Editing][LetterSizeY] / 4.0);						
						}

						case 2: 
						{
							Textdraw[ITDE_Editing][LetterSizeX] -= tmp;
							Textdraw[ITDE_Editing][LetterSizeY] = (Textdraw[ITDE_Editing][LetterSizeX] * 4.0);
						}
							
						case 3:
						{
							Textdraw[ITDE_Editing][LetterSizeX] += tmp;
							Textdraw[ITDE_Editing][LetterSizeY] = (Textdraw[ITDE_Editing][LetterSizeX] * 4.0);						
						} 						 
					}
				}
				else 
				{
					switch(direction)
					{
						case 0: Textdraw[ITDE_Editing][LetterSizeY] -= tmp;
						case 1: Textdraw[ITDE_Editing][LetterSizeY] += tmp;
						case 2: Textdraw[ITDE_Editing][LetterSizeX] -= tmp;
						case 3: Textdraw[ITDE_Editing][LetterSizeX] += tmp;
					}
				}


				format(string, sizeof string, "~y~X: ~w~%.1f  ~y~Y: ~w~%.1f", Textdraw[ITDE_Editing][LetterSizeX], Textdraw[ITDE_Editing][LetterSizeY]);
				GameTextForPlayer(ITDE_Player, string, 1000, 5);	

				TextDrawLetterSize(Textdraw[ITDE_Editing][Textid], Textdraw[ITDE_Editing][LetterSizeX], Textdraw[ITDE_Editing][LetterSizeY]);
				TextDrawShowForPlayer(ITDE_Player, Textdraw[ITDE_Editing][Textid]);				
			}
		}				
	}
	return 1;
}


forward Show_DialogOptions(); public Show_DialogOptions()
{
	Dialog_Options(ITDE_Player);
}


// ------------------------------------------------------------------------------
// COMMANDS
// ------------------------------------------------------------------------------


CMD:itde(playerid, params[])
{
	if(isequal(params, "exit", true))
	{
		EditorExit();
	}
	else
	{
		if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
			return SendClientMessage(playerid, -1, "[ITDE]: You are not onfoot.");


		if(ITDE_Player == INVALID_PLAYER_ID)
		{		
			TogglePlayerControllable(playerid, false);
			ITDE_Player = playerid;

			SendClientMessage(playerid, -1, "* ------------------------------------------------------------------------- *");
			SendClientMessage(playerid, -1, " ");
			SendClientMessage(playerid, -1, " » Injury's Text Draw Editor started «");
			SendClientMessage(playerid, -1, " ");
			SendClientMessage(playerid, -1, "» Use \"/itde exit\" to close the editor.");
			SendClientMessage(playerid, -1, "» Press \"~k~~PED_DUCK~\" to copy a textdraw while editing.");
			SendClientMessage(playerid, -1, "» Hold \"~k~~SNEAK_ABOUT~\" to slow movement while editing.");
			SendClientMessage(playerid, -1, "» Hold \"~k~~PED_SPRINT~\" to fast movement while editing.");
			SendClientMessage(playerid, -1, " ");
			SendClientMessage(playerid, -1, "* ------------------------------------------------------------------------- *");			
		}

		if(ITDE_ValidProject) Dialog_Show(playerid, CONTINUE_PROJECT, DIALOG_STYLE_LIST, "Injury's Text Draw Editor", "Continue Current Project\nExport & Close Current Project\nClose Current Project", "Select", "Cancel");
		else Dialog_Main(playerid);
	}
	return 1;
}


// ------------------------------------------------------------------------------
//	HOOKS
// ------------------------------------------------------------------------------


public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(ITDE_Timer != -1)
	{
		if(newkeys & KEY_SECONDARY_ATTACK)
		{
			KillTimer(ITDE_Timer);
			ITDE_Timer = -1;

			SetTimer("Show_DialogOptions", 100, false); // bug fix
		}
	}

	#if defined ITDE_OnPlayerKeyStateChange
		return ITDE_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
	#else
		return 1;
	#endif
}

#if defined _ALS_OnPlayerKeyStateChange
	#undef OnPlayerKeyStateChange
#else
	#define _ALS_OnPlayerKeyStateChange
#endif

#define OnPlayerKeyStateChange ITDE_OnPlayerKeyStateChange
#if defined ITDE_OnPlayerKeyStateChange
	forward ITDE_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
#endif


public OnFilterScriptExit()
{
	EditorExit();
	#if defined ITDE_OnFilterScriptExit
		return ITDE_OnFilterScriptExit();
	#else
		return 1;
	#endif
}

#if defined _ALS_OnFilterScriptExit
	#undef OnFilterScriptExit
#else
	#define _ALS_OnFilterScriptExit
#endif

#define OnFilterScriptExit ITDE_OnFilterScriptExit
#if defined ITDE_OnFilterScriptExit
	forward ITDE_OnFilterScriptExit();
#endif