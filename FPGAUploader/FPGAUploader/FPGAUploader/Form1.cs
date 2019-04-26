using FPGAUploader.Properties;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace FPGAUploader
{
    public partial class Form1 : Form
    {
        public List<string> lines = new List<string>();


        FileSystemWatcher watcher;

        DateTime timeoutUntil = DateTime.MinValue;

        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            selectedFile.Text = Settings.Default.selectedFile;
            UpdateFileHook();
        }

        private void UpdateFileHook()
        {
            if (selectedFile.Text == "- - -") return;
            watcher = new FileSystemWatcher();
            watcher.Path = new FileInfo(selectedFile.Text).Directory.FullName;
            watcher.Filter ="*"+ new FileInfo(selectedFile.Text).Name;
            watcher.EnableRaisingEvents = true;
            watcher.Changed += OnChanged;

            OnChanged(null,null);
        }

        private void OnChanged(object sender, FileSystemEventArgs e)
        {
            if ((DateTime.Now - timeoutUntil).TotalMilliseconds < 0) return;

            timeoutUntil = DateTime.Now.AddSeconds(45);

            Console.WriteLine("File changed!");
            lines.Clear();
            using (StreamReader reader = new StreamReader(selectedFile.Text))
            {
                while (reader.EndOfStream == false) lines.Add(reader.ReadLine());
            }

            for(int i=0;i<lines.Count;i++)
            {
                int start = int.Parse(lines[i].Substring(3,4), System.Globalization.NumberStyles.HexNumber);
                lines[i] = lines[i].Substring(1, 2) + (start / 2).ToString("X4") + lines[i].Substring(7, lines[i].Length - 7-2);
                int count = 0;
                for (int j=0;j<lines[i].Length;j+=2)
                {
                    count += int.Parse(lines[i].ElementAt(j)+""+ lines[i].ElementAt(j+1),System.Globalization.NumberStyles.HexNumber);
                }
                int a= (~count) + 1;
                a = a & 0x000000FF;
                lines[i] += (a).ToString("X2");
                lines[i] = ":" + lines[i];
            }

            using (StreamWriter writer = new StreamWriter(selectedFile.Text))
            {
                foreach (string line in lines) writer.WriteLine(line);
            }
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if(openFileDialog1.ShowDialog()==DialogResult.OK)
            {
                selectedFile.Text = openFileDialog1.FileName;

                Settings.Default.selectedFile = selectedFile.Text;
                Settings.Default.Save();
                UpdateFileHook();
            }
            
        }
    }
}
