using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using AGL;
using AGL.Forms;
using AGL.Mapping;
using AGL.Text;
using AGL.Imaging;
using AGL.Input;

namespace TestMonoGame
{
    public class Editor : Game
    {
		const int EDITOR_WIDTH = 1024;
		const int EDITOR_HEIGHT = 576;

        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;

        OrtogonalMap map;
        Texture2D empty, rect, selected, rampLeft, rampRight, hideTile;
        Texture2D[] tilesets, elements, backgrounds;
        Cell[,] objects;
        List<string> ramps, bgs;
        IntVector2 margin;
        Rectangle[] tiles;
        Rectangle editableArea, elementArea, rampArea;

        ImageFont font;
        TextField name, tilesX, tilesY, openName, paramString, rampArgs;
        Button generateMap, nextTileSet, nextElement, prevElement, nextType, nextExitType,
			nextBackground, addBackground, removeBackground, saveFile, openFile, clear, gridOnOff;

        MouseHandler mouse;
        KeyboardHandler keyboard;
        byte fieldFocused, currentTileset, elementIndex, tileType, currentBG;
        int qtTilesX, qtTilesY, currentElement, exitType;
		int[] switchCodes = {7, 8, 9, 12, 13, 20, 24, 26, 27, 31};
		string[] tileNames = {"Wall", "Passable", "Background", "Foreground", "Hide"},
			bgFiles = {"1.jpg", "2.png", "3.jpg", "4.jpg", "5.jpg"},
			exitTypes = {"Acima", "Direita", "Abaixo", "Esquerda", "Nenhuma"};

        DirectoryInfo dir;
        string message, message2;
        bool confirm, grid;

        struct Cell
        {
            string back, obj, fore, hide;
            public string Back { get { return back; } set { back = value; } }
            public string Obj { get { return obj; } set { obj = value; } }
            public string Fore { get { return fore; } set { fore = value; } }
            public string Hide { get { return hide; } set { hide = value; } }
        }

        public Editor()
        {
            graphics = new GraphicsDeviceManager(this);
//			graphics.PreferredBackBufferWidth = 800;
//			graphics.PreferredBackBufferHeight = 600;
//			graphics.ApplyChanges ();

            Content.RootDirectory = "Content";
        }

        protected override void Initialize()
        {
			Window.AllowUserResizing = true;
			Window.Title = "Super Bombinhas - Editor de fases";
			
            mouse = new MouseHandler(30, 8);
            IsMouseVisible = true;
            keyboard = new KeyboardHandler(new Keys[] { Keys.Up, Keys.Right, Keys.Down, Keys.Left,
				Keys.LeftShift, Keys.RightShift }, 30);

            qtTilesX = 300; qtTilesY = 300;
            map = new OrtogonalMap(32, 32, 300, 300, new IntVector2(EDITOR_WIDTH, EDITOR_HEIGHT));
            map.Camera.MinimumAllowedX = 0;
            map.Camera.MaximumAllowedX = map.AbsoluteSize.X - EDITOR_WIDTH;
            map.Camera.MinimumAllowedY = 0;
            map.Camera.MaximumAllowedY = map.AbsoluteSize.Y - EDITOR_HEIGHT;
            objects = new Cell[qtTilesX, qtTilesY];
            margin = new Vector2(200, 0);

            tiles = new Rectangle[64];
            for (int i = 0; i < 64; i++)
                tiles[i] = new Rectangle(4 + (i % 8) * 24, 200 + (i / 8) * 24, 24, 24);

            editableArea = new Rectangle(200, 0, EDITOR_WIDTH, EDITOR_HEIGHT);
            elementArea = new Rectangle(26, 435, 64, 64);
            rampArea = new Rectangle(118, 435, 64, 64);
            ramps = new List<string>();

            fieldFocused = 255;
            currentElement = 1;
			bgs = new List<string>();
			currentBG = 0;
            grid = true;

			exitType = 1;

            dir = new DirectoryInfo("/home/victor/aleva/super-bombinhas/data/stage");
            message = "";
            message2 = "";

            base.Initialize();
        }

        protected override void LoadContent()
        {
            spriteBatch = new SpriteBatch(GraphicsDevice);
			
			Texture2D fontImg = Content.Load<Texture2D>("BankGothic");
            font = new BasicImageFont(fontImg) { Color = Color.Black, Scale = 0.6f, CharSpacing = 1, LineSpacing = -2 };

			BasicDrawer.GD = GraphicsDevice;
            Texture2D field = BasicDrawer.GetOutlineFilledRectangle(192, 18, Color.Black, Color.White),
                cursor = BasicDrawer.GetFilledRectangle(2, 14, Color.Black),
                btnUp = BasicDrawer.GetOutlineGradientRectangle(192, 18, Color.DarkGray, Color.LightGray, Color.Black, GradientDirection.Vertical),
                btnOver = BasicDrawer.GetOutlineGradientRectangle(192, 18, Color.LightGray, Color.White, Color.Black, GradientDirection.Vertical),
                btnDown = BasicDrawer.GetOutlineGradientRectangle(192, 18, Color.Gray, Color.DarkGray, Color.Black, GradientDirection.Vertical);
			Texture2D[] btn = new[] { btnUp, btnOver, btnDown };

			hideTile = GetTex("ForeWall");

			name = new TextField(new Vector2(4, 25), new Rectangle(0, 0, 192, 18), field, new Vector2(1, 2), cursor, 
                new Color(Color.Blue, 100), new Vector2(2, 0), 30, font, GraphicsDevice);
            tilesX = new TextField(new Vector2(4, 65), new Rectangle(0, 0, 192, 18), field, new Vector2(1, 2), cursor,
                new Color(Color.Blue, 100), new Vector2(2, 0), 3, font, GraphicsDevice);
            tilesY = new TextField(new Vector2(4, 105), new Rectangle(0, 0, 192, 18), field, new Vector2(1, 2), cursor,
                new Color(Color.Blue, 100), new Vector2(2, 0), 3, font, GraphicsDevice);
            paramString = new TextField(new Vector2(4, 536), new Rectangle(0, 0, 192, 18), field, new Vector2(1, 2), cursor,
                new Color(Color.Blue, 100), new Vector2(2, 0), 30, font, GraphicsDevice);
            rampArgs = new TextField(new Vector2(4, 554), new Rectangle(0, 0, 192, 18), field, new Vector2(1, 2), cursor,
			    new Color(Color.Blue, 100), new Vector2(2, 0), 3, font, GraphicsDevice);
			generateMap = new Button(new Vector2(4, 125), btn, "Gerar mapa", new Vector2(), true, font);
            nextTileSet = new Button(new Vector2(4, 392), btn, "Próximo", new Vector2(), true, font);
            nextType = new Button(new Vector2(4, 172), btn, "Próximo", new Vector2(), true, font);
            nextElement = new Button(new Vector2(4, 500), btn, "Próximo", new Vector2(), true, font);
            prevElement = new Button(new Vector2(4, 518), btn, "Anterior", new Vector2(), true, font);
			nextExitType = new Button(new Vector2(4, 588), btn, "Próximo", new Vector2(), true, font);
            nextBackground = new Button(new Vector2(204, 560+120), btn, "Próximo", new Vector2(), true, font);
            addBackground = new Button(new Vector2(204, 580+120), btn, "Adicionar", new Vector2(), true, font);
            removeBackground = new Button(new Vector2(404, 580+120), btn, "Remover", new Vector2(), true, font);
			saveFile = new Button(new Vector2(4, 645), btn, "Salvar", new Vector2(), true, font);
			openName = new TextField(new Vector2(604, 560+120), new Rectangle(0, 0, 192, 18), field, new Vector2(1, 2), cursor,
                new Color(Color.Blue, 100), new Vector2(2, 0), 30, font, GraphicsDevice);
			openFile = new Button(new Vector2(604, 580+120), btn, "Abrir", new Vector2(), true, font);
            clear = new Button(new Vector2(604, 455+126), btn, "Limpar", new Vector2(), true, font);
            gridOnOff = new Button(new Vector2(604, 485+126), btn, "Grid on/off", new Vector2(), true, font);
            
			empty = BasicDrawer.GetOutlineFilledRectangle(32, 32, Color.LightGray, Color.White);
            rect = BasicDrawer.GetHorizontalLine(1, Color.White);
            selected = BasicDrawer.OverlapTextures(BasicDrawer.GetOutlineRectangle(24, 24, Color.Yellow), new Texture2D[]{
                BasicDrawer.GetOutlineRectangle(22, 22, Color.Black), BasicDrawer.GetOutlineRectangle(20, 20, Color.Yellow)}, new IntVector2[]{
                new IntVector2(1, 1), new IntVector2(2, 2)}, false);
            rampLeft = BasicDrawer.GetFilledTriangle(96, new Color(Color.Black, 100), TriangleType.BottomRight);
            rampRight = BasicDrawer.GetFilledTriangle(96, new Color(Color.Black, 100), TriangleType.BottomLeft);
            tilesets = new Texture2D[2];
            for (int i = 0; i < tilesets.Length; i++)
                tilesets[i] = Content.Load<Texture2D>("Tilesets/" + (i + 1));
            elements = new Texture2D[]
            {
                GetTex("BombaAzulD1"),
                GetTex("WheeliamE1"),
                GetTex("PedraFogo1"),
                GetTex("BombieE1"),
                GetTex("SprinnyE1"),
                GetTex("SprinnyE2"),
                GetTex("SprinnyE3"),
                GetTex("Life"),
                GetTex("Key"),
                GetTex("Door"),
                GetTex("DoorLocked"),
                GetTex("DoorExit"),
                GetTex("GunPowder"),
                GetTex("Crack"),
                GetTex("SemiWall1"),
                GetTex("SemiWall2"),
                GetTex("WheeliamFall"),
                GetTex("Elevator1"),
                GetTex("Fureel1"),
                GetTex("FureelFall"),
                GetTex("Bombie2"),
                GetTex("Pin1"),
                GetTex("Pin2"),
                GetTex("Spikes1"),
                GetTex("Atk1Icon"),
                GetTex("MovingWall"),
                GetTex("Ball"),
                GetTex("BallX"),
                GetTex("Yaw"),
                GetTex("Ekips"),
                GetTex("ForeWall"),
                GetTex("Spec"),
                GetTex("Faller"),
                GetTex("Turner")
            };
            
			backgrounds = new Texture2D[bgFiles.Length];
			for (int i = 0; i < bgFiles.Length; i++)
				backgrounds[i] = Content.Load<Texture2D>("Backgrounds/" + bgFiles[i]);
        }
        private Texture2D GetTex(string element)
        {
            return Content.Load<Texture2D>("Elements/" + element);
        }

        protected override void UnloadContent()
        {
        }

        protected override void Update(GameTime gameTime)
        {
            if (IsActive)
            {
                #region Mouse
                mouse.Update();
                if (mouse.IsLeftButtonDown)
                {
                    if (mouse.IsLeftButtonPressed)
                    {
                        if (mouse.IsCursorOver(name.ActiveArea))
                        {
                            fieldFocused = 0;
                            confirm = false;
                        }
                        else if (mouse.IsCursorOver(tilesX.ActiveArea))
                            fieldFocused = 1;
                        else if (mouse.IsCursorOver(tilesY.ActiveArea))
                            fieldFocused = 2;
                        else if (mouse.IsCursorOver(openName.ActiveArea))
                            fieldFocused = 3;
                        else if (mouse.IsCursorOver(paramString.ActiveArea))
                            fieldFocused = 4;
                        else if (mouse.IsCursorOver(rampArgs.ActiveArea))
                            fieldFocused = 5;
                        else if (mouse.IsCursorOver(editableArea))
                        {
							if (currentElement < 0) // ramp
							{
								IntVector2 mapPos = map.GetPosition(mouse.Position - margin);
	                            ramps.Add(rampArgs.Text + ":" + mapPos.X + "," + mapPos.Y);
							}
                        }
                        else
                        {
                            for (byte i = 0; i < 64; i++)
                                if (mouse.IsCursorOver(tiles[i]))
                                {
                                    currentElement = ++i;
                                    break;
                                }
                            if (mouse.IsCursorOver(elementArea))
                                currentElement = 65 + elementIndex;
                            else if (mouse.IsCursorOver(rampArea))
                                currentElement = -1;
                            fieldFocused = 255;
                        }
                    }
                    if (mouse.IsCursorOver(editableArea) && currentElement > 0)
                    {
                        IntVector2 mapPos = map.GetPosition(mouse.Position - margin);
                        if (mouse.IsLeftButtonDoubleClicked)
                        {
                            if (currentElement <= 64 && tileType == 2 || tileType == 4)
                            {
                                string code = "b" + (currentElement - 1).ToString("00");
                                CheckFill(mapPos.X, mapPos.Y, code);
                            }
                        }
                        else if (currentElement <= 64)
                        {
                            if (tileType == 0 || tileType == 1)
                                objects[mapPos.X, mapPos.Y].Obj = (tileType == 0 ? "w" : "p") + (currentElement - 1).ToString("00");
                            else if (tileType == 2)
                                objects[mapPos.X, mapPos.Y].Back = "b" + (currentElement - 1).ToString("00");
                            else if (tileType == 3)
                                objects[mapPos.X, mapPos.Y].Fore = "f" + (currentElement - 1).ToString("00");
							else
                                objects[mapPos.X, mapPos.Y].Hide = "h00";
                        }
                        else if (currentElement == 65) //bomba
						{
							if (paramString.Text != string.Empty)
                            	objects[mapPos.X, mapPos.Y].Obj = "!" + paramString.Text;
						}
                        else
                        {
							string symbol = IsSwitch(currentElement - 65) ? "$" : "@";
                            objects[mapPos.X, mapPos.Y].Obj = symbol + (currentElement - 65);
                            if (paramString.Text != string.Empty)
                            	objects[mapPos.X, mapPos.Y].Obj += ":" + paramString.Text;
                        }
                    }
                }
                else if (mouse.IsRightButtonDown)
                {
                    if (mouse.IsCursorOver(editableArea))
                    {
                        IntVector2 mapPos = map.GetPosition(mouse.Position - margin);
                        foreach (string ramp in ramps)
                        {
                            int x = int.Parse(ramp.Split(':')[1].Split(',')[0]),
								y = int.Parse(ramp.Split(':')[1].Split(',')[1]),
								w = int.Parse(ramp[1] + "") * 32,
								h = int.Parse(ramp[2] + "") * 32;
                            IntVector2 pos = map.GetScreenPosition(new IntVector2(x, y)) + margin;
                            if (mouse.IsCursorOver(new Rectangle(pos.X, pos.Y, w, h)))
                            {
								ramps.Remove(ramp);
								break;
							}
                        }
                        objects[mapPos.X, mapPos.Y] = new Cell();
                    }
                }
                #endregion

                #region Keyboard
                if (fieldFocused == 0) name.Update();
                else if (fieldFocused == 1) tilesX.Update();
                else if (fieldFocused == 2) tilesY.Update();
                else if (fieldFocused == 3) openName.Update();
                else if (fieldFocused == 4) paramString.Update();
                else if (fieldFocused == 5) rampArgs.Update();
                else
                {
                    keyboard.Update();
                    int speed = keyboard.IsKeyDown(4) ? 20 : 10;
                    if (keyboard.IsKeyDown(0))
                        map.Camera.SetOrigin(map.Camera.Origin + new IntVector2(0, -speed));
                    if (keyboard.IsKeyDown(1))
                        map.Camera.SetOrigin(map.Camera.Origin + new IntVector2(speed, 0));
                    if (keyboard.IsKeyDown(2))
                        map.Camera.SetOrigin(map.Camera.Origin + new IntVector2(0, speed));
                    if (keyboard.IsKeyDown(3))
                        map.Camera.SetOrigin(map.Camera.Origin + new IntVector2(-speed, 0));
                }
                #endregion

                #region Buttons
                generateMap.Update();
                if (generateMap.Clicked)
                {
                    if (tilesX.Text != string.Empty && tilesY.Text != string.Empty)
                    {
                        int prevTilesX = qtTilesX, prevTilesY = qtTilesY;
                        qtTilesX = int.Parse(tilesX.Text); qtTilesY = int.Parse(tilesY.Text);
                        map = new OrtogonalMap(32, 32, qtTilesX, qtTilesY, new IntVector2(EDITOR_WIDTH, EDITOR_HEIGHT));
                        map.Camera.MinimumAllowedX = 0;
                        map.Camera.MaximumAllowedX = map.AbsoluteSize.X - EDITOR_WIDTH < 0 ? 0 : map.AbsoluteSize.X - EDITOR_WIDTH;
                        map.Camera.MinimumAllowedY = 0;
                        map.Camera.MaximumAllowedY = map.AbsoluteSize.Y - EDITOR_HEIGHT < 0 ? 0 : map.AbsoluteSize.Y - EDITOR_HEIGHT;
                        Cell[,] newObjects = new Cell[qtTilesX, qtTilesY];
                        for (int i = 0; i < prevTilesX && i < qtTilesX; i++)
                            for (int j = 0; j < prevTilesY && j < qtTilesY; j++)
                                newObjects[i, j] = objects[i, j];
                        objects = newObjects;
                    }
                }
                nextTileSet.Update();
                if (nextTileSet.Clicked)
                {
                    if (currentTileset == tilesets.Length - 1) currentTileset = 0;
                    else currentTileset++;
                }
                nextType.Update();
                if (nextType.Clicked)
                {
                    if (tileType == 4) tileType = 0;
                    else tileType++;
                    if (currentElement > 64) currentElement = 1;
                }
                nextElement.Update();
                if (nextElement.Clicked)
                {
                    if (elementIndex == elements.Length - 1) elementIndex = 0;
                    else elementIndex++;
                    currentElement = 65 + elementIndex;
                }
                prevElement.Update();
                if (prevElement.Clicked)
                {
                    if (elementIndex == 0) elementIndex = (byte)(elements.Length - 1);
                    else elementIndex--;
                    currentElement = 65 + elementIndex;
                }
                
				nextExitType.Update();
				if (nextExitType.Clicked)
				{
					exitType++;
					if (exitType == exitTypes.Length) exitType = 0;
				}

				nextBackground.Update();
                if (nextBackground.Clicked)
                {
					currentBG++;
                    if (currentBG == backgrounds.Length) currentBG = 0;
                }
				addBackground.Update();
				if (addBackground.Clicked && bgs.Count < 5)
					bgs.Add((currentBG + 1) + "");
				removeBackground.Update();
				if (removeBackground.Clicked && bgs.Count > 0)
					bgs.RemoveAt(0);
                
				saveFile.Update();
                if (saveFile.Clicked)
                {
                    FileInfo file = new FileInfo(dir.FullName + "/" + name.Text + ".sbs");
                    if (confirm)
                    {
                        confirm = false;
                        file.Delete();
                        SaveFile(file);
                        message = "Arquivo salvo.";
                    }
                    else
                    {
                        if (name.Text == string.Empty)
                            message = "Dê um nome à fase!";
                        else
                        {
                            if (file.Exists)
                            {
                                message = "Salvar por cima?";
                                confirm = true;
                            }
                            else
                            {
                                SaveFile(file);
                                message = "Arquivo salvo.";
                            }
                        }
                    }
                }
                openFile.Update();
                if (openFile.Clicked)
                {
                    if (openName.Text == string.Empty) message2 = "Digite o nome!";
                    else
                    {
                        FileInfo file = new FileInfo(dir.FullName + "/" + openName.Text + ".sbs");
                        if (!file.Exists) message2 = "Não existe!";
                        else
                        {
                            OpenFile(file);
                            message2 = "Arquivo aberto.";
                        }
                    }
                }
                clear.Update();
                if (clear.Clicked)
                {
                    name.Text = ""; name.Update();
                    tilesX.Text = ""; tilesX.Update();
                    tilesY.Text = ""; tilesY.Update();
                    openName.Text = ""; openName.Update();
                    currentElement = 1;
                    currentTileset = 0;
                    currentBG = 0;
                    qtTilesX = 300; qtTilesY = 300;
                    map = new OrtogonalMap(32, 32, qtTilesX, qtTilesY, new IntVector2(EDITOR_WIDTH, EDITOR_HEIGHT));
                    map.Camera.MinimumAllowedX = 0;
                    map.Camera.MaximumAllowedX = map.AbsoluteSize.X - EDITOR_WIDTH;
                    map.Camera.MinimumAllowedY = 0;
                    map.Camera.MaximumAllowedY = map.AbsoluteSize.Y - EDITOR_HEIGHT;
                    ramps.Clear();
                    objects = new Cell[300, 300];
                }
                gridOnOff.Update();
                if (gridOnOff.Clicked) grid = !grid;
                #endregion

                base.Update(gameTime);
            }
        }

		private bool IsSwitch (int code)
		{
			for (int i = 0; i < switchCodes.Length; i++)
				if (switchCodes[i] == code)
					return true;
			return false;
		}

        private void CheckFill(int i, int j, string code)
        {
			if (tileType == 2) objects[i, j].Back = code;
			else objects[i, j].Hide = "h00";
            if (i > 0 && IsCellEmpty(i - 1, j, tileType == 4))
                CheckFill(i - 1, j, code);
            if (i < qtTilesX - 1 && IsCellEmpty(i + 1, j, tileType == 4))
                CheckFill(i + 1, j, code);
            if (j > 0 && IsCellEmpty(i, j - 1, tileType == 4))
                CheckFill(i, j - 1, code);
            if (j < qtTilesY - 1 && IsCellEmpty(i, j + 1, tileType == 4))
                CheckFill(i, j + 1, code);
        }

        private void SaveFile(FileInfo file)
        {
            StreamWriter sw = file.CreateText();
            string code = qtTilesX + "," + qtTilesY + "," + exitType + "," + (currentTileset + 1) + "#",
                lastElement = GetCellString(0, 0);
			for (int i = 0; i < bgs.Count - 1; i++)
				code += bgs[i] + ",";
			code += bgs[bgs.Count - 1] + "#";
			int count = 1;
            for (int j = 0; j < qtTilesY; j++)
            {
                for (int i = 0; i < qtTilesX; i++)
                {
                    if (i == 0 && j == 0) i++;
                    if (GetCellString(i, j) == lastElement &&
					    (lastElement == "" || 
					    ((lastElement[0] == 'w' ||
					      lastElement[0] == 'p' ||
					      lastElement[0] == 'b' ||
					      lastElement[0] == 'f' ||
					      lastElement[0] == 'h') && lastElement.Length == 3)))
						count++;
                    else 
                    {
                        code += (lastElement == "" ? ("_" + count) : (lastElement + (count > 1 ? "*" + count : ""))) + ";";
                        lastElement = GetCellString(i, j);
                        count = 1;
                    }
                }
            }
            if (lastElement == "") code = code.Substring(0, code.Length - 1) + "#";
            else code += lastElement + (count > 1 ? "*" + count : "") + "#";
            for (int i = 0; i < ramps.Count; i++)
            {
                code += ramps[i];
                if (i < ramps.Count - 1) code += ";";
            }
            sw.WriteLine(code);
            sw.Close();
        }

        private void OpenFile(FileInfo file)
        {
            StreamReader sr = file.OpenText();
            string[] all = sr.ReadLine().Split('#'), infos = all[0].Split(','), bgInfos = all[1].Split(','), elms = all[2].Split(';');
			qtTilesX = int.Parse(infos[0]); qtTilesY = int.Parse(infos[1]); exitType = int.Parse (infos[2]);
            map = new OrtogonalMap(32, 32, qtTilesX, qtTilesY, new IntVector2(EDITOR_WIDTH, EDITOR_HEIGHT));
            map.Camera.MinimumAllowedX = 0;
            map.Camera.MaximumAllowedX = map.AbsoluteSize.X - EDITOR_WIDTH < 0 ? 0 : map.AbsoluteSize.X - EDITOR_WIDTH;
            map.Camera.MinimumAllowedY = 0;
            map.Camera.MaximumAllowedY = map.AbsoluteSize.Y - EDITOR_HEIGHT < 0 ? 0 : map.AbsoluteSize.Y - EDITOR_HEIGHT;
            objects = new Cell[qtTilesX, qtTilesY];
            
			bgs.Clear();
			for (int k = 0; k < bgInfos.Length; k++)
				bgs.Add(bgInfos[k]);
			currentBG = 0;

			currentTileset = (byte)(byte.Parse(infos[3]) - 1);
            int i = 0, j = 0;
            foreach (string e in elms)
            {
                if (e[0] == '_')
				{
					i += int.Parse (e.Substring(1));
	                if (i >= map.Size.X)
	                {
	                    j += i / map.Size.X;
	                    i %= map.Size.X;
	                }
				}
				else if (e.Length > 3 && e[3] == '*')
				{
					int amount = int.Parse(e.Substring(4));
					string tile = e.Substring(0, 3);
					for (int k = 0; k < amount; k++)
					{
						if (e[0] == 'b') objects[i++, j].Back = tile;
						else if (e[0] == 'f') objects[i++, j].Fore = tile;
						else if (e[0] == 'h') objects[i++, j].Hide = tile;
						else objects[i++, j].Obj = tile;

						if (i == qtTilesX) { i = 0; j++; }
					}
				}
				else
				{
					int ind = 0;
					while (ind < e.Length)
					{
						if (e[ind] == 'b') objects[i, j].Back = e.Substring(ind, 3);
						else if (e[ind] == 'f') objects[i, j].Fore = e.Substring(ind, 3);
						else if (e[ind] == 'h') objects[i, j].Hide = e.Substring(ind, 3);
						else if (e[ind] == 'p' || e[ind] == 'w') objects[i, j].Obj = e.Substring(ind, 3);
						else
						{
							objects[i, j].Obj = e.Substring(ind);
							ind += 1000;
						}
						ind += 3;
					}
					i++;
					if (i == qtTilesX) { i = 0; j++; }
				}
            }
            ramps.Clear();
            if (all[3] != string.Empty)
            {
                string[] rmps = all[3].Split(';');
                foreach (string str in rmps) ramps.Add(str);
            }
            name.Text = openName.Text;
        }

        private string GetCellString(int i, int j)
        {
            string str = "";
            if (objects[i, j].Back != null)
                str += objects[i, j].Back;
            if (objects[i, j].Fore != null)
                str += objects[i, j].Fore;
            if (objects[i, j].Hide != null)
                str += objects[i, j].Hide;
            if (objects[i, j].Obj != null)
                str += objects[i, j].Obj;
            return str;
        }

        private bool IsCellEmpty(int i, int j, bool back)
        {
            return
				(back || objects[i, j].Back == null) &&
				objects[i, j].Fore == null &&
				objects[i, j].Hide == null &&
				objects[i, j].Obj == null;
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.White);
            spriteBatch.Begin();
            if (grid) map.ForEachVisible(DrawNulls);
            map.ForEachVisible(DrawBacks);
            map.ForEachVisible(DrawObjs);
            map.ForEachVisible(DrawFores);
            DrawRamps();
            spriteBatch.Draw(rect, new Rectangle(0, 0, 200, 600), Color.White);
            spriteBatch.Draw(rect, new Rectangle(200, 450+126, 600, 150), Color.White);
            font.DrawString("Nome:", new Vector2(5, 5), false, spriteBatch);
            font.DrawString("Tiles em X:", new Vector2(5, 45), false, spriteBatch);
            font.DrawString("Tiles em Y:", new Vector2(5, 85), false, spriteBatch);
            name.Draw(spriteBatch);
            tilesX.Draw(spriteBatch);
            tilesY.Draw(spriteBatch);
            openName.Draw(spriteBatch);
            paramString.Draw(spriteBatch);
			rampArgs.Draw(spriteBatch);
            generateMap.Draw(spriteBatch);
            nextTileSet.Draw(spriteBatch);
            nextElement.Draw(spriteBatch);
            prevElement.Draw(spriteBatch);
            nextType.Draw(spriteBatch);
            nextExitType.Draw(spriteBatch);
            nextBackground.Draw(spriteBatch);
            addBackground.Draw(spriteBatch);
            removeBackground.Draw(spriteBatch);
            saveFile.Draw(spriteBatch);
            openFile.Draw(spriteBatch);
            clear.Draw(spriteBatch);
            gridOnOff.Draw(spriteBatch);
            font.DrawString(message, new Vector2(100, 620), true, spriteBatch);
            font.DrawString(message2, new Vector2(700, 530+126), true, spriteBatch);
            spriteBatch.Draw(tilesets[currentTileset], new Rectangle(4, 200, 192, 192), Color.White);
            font.DrawString(tileNames[tileType], new Vector2(100, 150), true, spriteBatch);
            spriteBatch.Draw(elements[elementIndex], new Vector2(26 + (64 - elements[elementIndex].Width) / 2,
                435 + (64 - elements[elementIndex].Height) / 2), Color.White);
            spriteBatch.Draw(rampLeft, rampArea, Color.White);
            if (currentElement < 0) spriteBatch.Draw(selected, rampArea, Color.White);
            else if (currentElement <= 64)
                spriteBatch.Draw(selected, new Vector2(4 + ((currentElement - 1) % 8) * 24, 200 + ((currentElement - 1) / 8) * 24), Color.White);
            else spriteBatch.Draw(selected, elementArea, Color.White);
            
			font.DrawString("Saída: " + exitTypes[exitType], new Vector2(4, 568), false, spriteBatch);

			spriteBatch.Draw(backgrounds[currentBG], new Rectangle(204, 580, 192, 100), Color.White);
			for (int i = 0; i < bgs.Count; i++)
				font.DrawString(bgs[i], new Vector2(404, 580 + i * 20), false, spriteBatch);

			if (mouse.IsCursorOver(editableArea))
                font.DrawString(map.GetPosition(mouse.Position - margin).ToString(), mouse.Position + new Vector2(5, 0), false, spriteBatch);
            spriteBatch.End();
            base.Draw(gameTime);
        }

        private void DrawNulls(int i, int j, int x, int y)
        {
            spriteBatch.Draw(empty, new Vector2(x, y) + margin, Color.White);
        }
        private void DrawBacks(int i, int j, int x, int y)
        {
            if (objects[i, j].Back != null)
            {
				int index = int.Parse(objects[i, j].Back.Substring(1)), x2 = (index % 8) * 32, y2 = (index / 8) * 32;
                spriteBatch.Draw(tilesets[currentTileset], new Rectangle(x + margin.X, y + margin.Y, 32, 32), new Rectangle(x2, y2, 32, 32), Color.White);
            }
        }
        private void DrawObjs(int i, int j, int x, int y)
        {
            if (objects[i, j].Obj != null)
            {
                string s = objects[i, j].Obj;
                if (s[0] == 'w' || s[0] == 'p')
                {
					int index = int.Parse(s.Substring(1)), x2 = (index % 8) * 32, y2 = (index / 8) * 32;
                    spriteBatch.Draw(tilesets[currentTileset], new Rectangle(x + margin.X, y + margin.Y, 32, 32), new Rectangle(x2, y2, 32, 32), Color.White);
                    if (s.Length > 3) font.DrawString("b", new Vector2(x + margin.X, y + margin.Y), false, Color.White, spriteBatch);
                }
                else if (s[0] == '!')
                {
                    spriteBatch.Draw(elements[0], new Vector2(x + margin.X, y + margin.Y), Color.White);
                    font.DrawString(s[1] + "", new Vector2(x + margin.X, y + margin.Y), false, Color.Black, spriteBatch);
                }
                else
                {
                    string[] code = s.Substring(1).Split(':');
                    spriteBatch.Draw(elements[int.Parse(code[0])], new Vector2(x + margin.X, y + margin.Y), Color.White);
                    if (code.Length > 1)
                    {
                        string str = "";
                        for (int k = 1; k < code.Length; k++) str += code[k] + "\n";
                        font.DrawString(str, new Vector2(x + margin.X + 5, y + margin.Y), false, Color.Black, 0.3f, spriteBatch);
                    }
                }
            }
        }
        private void DrawFores(int i, int j, int x, int y)
        {
            if (objects[i, j].Fore != null)
            {
				int index = int.Parse(objects[i, j].Fore.Substring(1)), x2 = (index % 8) * 32, y2 = (index / 8) * 32;
                spriteBatch.Draw(tilesets[currentTileset], new Rectangle(x + margin.X, y + margin.Y, 32, 32), new Rectangle(x2, y2, 32, 32), Color.White);
            }
            if (objects[i, j].Hide != null)
				spriteBatch.Draw(hideTile, new Vector2(x + margin.X, y + margin.Y), Color.White);
        }
        private void DrawRamps()
        {
            foreach (string str in ramps)
            {
                string[] poss = str.Split(':')[1].Split(',');
                IntVector2 pos = map.GetScreenPosition(new IntVector2(int.Parse(poss[0]), int.Parse(poss[1]))) + margin;
                bool left = str[0] == 'l'; int x = int.Parse(str[1] + ""), y = int.Parse(str[2] + "");
                spriteBatch.Draw(left ? rampLeft : rampRight, new Rectangle(pos.X, pos.Y, x * 32, y * 32), Color.White);
            }
        }
    }
}
