using System;
using System.Collections.Generic;
using System.Linq;

namespace TestMonoGame
{
	static class Program
	{
		private static Editor game;

		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		[STAThread]
		static void Main ()
		{
			game = new Editor ();
			game.Run ();
		}
	}
}
