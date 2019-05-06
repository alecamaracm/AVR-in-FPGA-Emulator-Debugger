using FPGAUploader.Properties;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.IO.Ports;
using System.Linq;
using System.Text;
using System.Threading;
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
            outputFile.Text = Settings.Default.outputFile;
          

            port.BaudRate = 9600;
            port.Parity = Parity.None;
            port.StopBits = StopBits.One;
            port.Open();

            UpdateFileHook();
        }

        private void UpdateFileHook()
        {
            if (selectedFile.Text == "- - -") return;
            if (outputFile.Text == "- - -") return;
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

            timeoutUntil = DateTime.Now.AddSeconds(10);
            Thread.Sleep(2500);

            Console.WriteLine("File changed!");
            lines.Clear();
            using (StreamReader reader = new StreamReader(File.OpenRead(selectedFile.Text)))
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

            using (StreamWriter writer = new StreamWriter(outputFile.Text))
            {
                foreach (string line in lines) writer.WriteLine(line);
            }

            if (checkBox1.Checked == true) Programm();
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

        private void button2_Click(object sender, EventArgs e)
        {
            if (openFileDialog2.ShowDialog() == DialogResult.OK)
            {
                outputFile.Text = openFileDialog2.FileName;
                Settings.Default.outputFile = outputFile.Text;
                Settings.Default.Save();
                UpdateFileHook();
            }
        }

        private void button3_Click(object sender, EventArgs e)
        {
            /*  for(int i=0;i<300;i++)
              {
                  byte[] btt = new byte[] { (byte)(i%255) };
                  port.Write(btt, 0, btt.Length);

                  Thread.Sleep(100);
              }*/

            byte[] btt = new byte[] { (byte)( 255) };
            port.Write(btt, 0, btt.Length);
        }

        SerialPort port = new SerialPort("COM5");

        private void button4_Click(object sender, EventArgs e)
        {
            Programm();
//
        }

        private void Programm()
        {
            List<byte> toSend = new List<byte>();

            List<string> lines2 = new List<string>();

            using (StreamReader reader = new StreamReader(selectedFile.Text))
            {
                while (reader.EndOfStream == false) lines2.Add(reader.ReadLine());
            }

            for (int i = 0; i < lines2.Count; i++)
            {
                int start = int.Parse(lines2[i].Substring(3, 4), System.Globalization.NumberStyles.HexNumber);
                lines2[i] = lines2[i].Substring(1, 2) + (start / 2).ToString("X4") + lines2[i].Substring(7, lines2[i].Length - 7 - 2);
                for (int j = 8; j < lines2[i].Length; j += 2)
                {
                    toSend.Add(byte.Parse(lines2[i].ElementAt(j) + "" + lines2[i].ElementAt(j + 1), System.Globalization.NumberStyles.HexNumber));
                }
            }


            //Send handshake (Programming request)
            byte[] btt = new byte[] { 169, 68, 69 };
            port.Write(btt, 0, btt.Length);

            //Thread.Sleep(250);
            for (int i = 0; i < toSend.Count; i++)
            {
                byte[] btt2 = new byte[] { toSend[i] };
                port.Write(btt2, 0, btt2.Length);
                Thread.Sleep(10);
            }

            //        port.Write(toSend.ToArray(), 0, toSend.Count);
        }

        private void button3_Click_1(object sender, EventArgs e)
        {
            OnChanged(null, null);
        }
    }
}
