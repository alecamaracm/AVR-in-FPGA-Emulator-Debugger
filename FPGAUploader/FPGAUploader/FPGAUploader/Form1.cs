using FPGAUploader.Properties;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Globalization;
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

        byte lastPort11;
        byte lastPort5;

        FileSystemWatcher watcher;

        DateTime timeoutUntil = DateTime.MinValue;

        public Form1()
        {
            InitializeComponent();
            for(int i=0;i<32;i++)
            {
                var a = new ListViewItem("R"+i);
                
                a.SubItems.Add("0");
                listView1.Items.Add(a);
            }
            for (int i = 0; i < 64; i++)
            {
                var a = new ListViewItem("R" + i);
                if (i == 11)
                {
                    a.Text += " (IO 0-7)";
                }
                if (i == 5)
                {
                    a.Text += " (IO 8-13)";
                }
                if (i == 61)
                {
                    a.Text += " (SP Low)";
                }
                if (i == 62)
                {
                    a.Text += " (SP High)";
                }
                a.SubItems.Add("0");
                listView2.Items.Add(a);
            }
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            selectedFile.Text = Settings.Default.selectedFile;
            outputFile.Text = Settings.Default.outputFile;
          

            port.BaudRate = 115200;
            port.Parity = Parity.None;
            port.StopBits = StopBits.One;
            port.Open();

            Thread thread = new Thread(ReadUART);
            thread.SetApartmentState(ApartmentState.STA);
            thread.IsBackground = true;
            thread.Start();

            UpdateFileHook();
            this.DoubleBuffered = true;
        }

        byte[] buffer = new byte[6];

        int lastSelectedIndex = -1;

        private void ReadUART()
        {
            while(true)
            {
                if(port.BytesToRead>=6)
                {
                    port.Read(buffer, 0, 6);
                    if(buffer[0]==42) //Good message
                    {
                        this.Invoke((MethodInvoker)delegate () {
                            try
                            {
                                switch (buffer[1])
                                {
                                    case 5: //PC
                                        int pc = buffer[2];
                                        pc = pc << 2;
                                        pc += buffer[3];
                                         labelIName.Text = getInstructionName(buffer[5]);
                                        labelPC.Text = "0x" + (pc * 2).ToString("X4") + " (" + getState(buffer[4]) + ")";

                                        if(lastSelectedIndex!=-1 && listViewNF1.Items.Count>lastSelectedIndex)
                                        {
                                            listViewNF1.Items[lastSelectedIndex].BackColor = Color.LightBlue;
                                        }

                                        if(lineToIndex.ContainsKey(pc*2))
                                        {
                                            lastSelectedIndex = lineToIndex[pc * 2];
                                            if (listViewNF1.Items.Count > lastSelectedIndex)
                                            {
                                                listViewNF1.Items[lastSelectedIndex].BackColor = Color.Orange;
                                            }
                                        }


                                        break;
                                    case 12: //REGS
                                        listView1.Items[buffer[2]].SubItems[1].Text = buffer[3] + "";
                                        listView1.Items[buffer[2] + 1].SubItems[1].Text = buffer[4] + "";
                                        listView1.Items[buffer[2] + 2].SubItems[1].Text = buffer[5] + "";
                                        break;
                                    case 14: //SP
                                        int sp = buffer[2];
                                        sp = sp << 2;
                                        sp += buffer[3];
                                        labelSP.Text = "0x" + (sp).ToString("X4");
                                        break;
                                    case 13: //IOREGS
                                        if(buffer[2]==11)
                                        {
                                            lastPort11 = buffer[3];
                                        }
                                        if (buffer[2] == 5)
                                        {
                                            lastPort5 = buffer[3];
                                        }
                                        if (buffer[2]+1 == 11)
                                        {
                                            lastPort11 = buffer[4];
                                        }
                                        if (buffer[2]+1 == 5)
                                        {
                                            lastPort5 = buffer[4];
                                        }
                                        if (buffer[2] + 2 == 11)
                                        {
                                            lastPort11 = buffer[5];
                                        }
                                        if (buffer[2] + 2 == 5)
                                        {
                                            lastPort5 = buffer[5];
                                        }
                                        listView2.Items[buffer[2]].SubItems[1].Text = buffer[3] + "";
                                        listView2.Items[buffer[2] + 1].SubItems[1].Text = buffer[4] + "";
                                        listView2.Items[buffer[2] + 2].SubItems[1].Text = buffer[5] + "";
                                        break;
                                    case 15:
                                        int d1 = buffer[2];
                                        d1 = d1 << 2;
                                        d1 += buffer[3];
                                        int d2 = buffer[4];
                                        d2 = d2 << 2;
                                        d2 += buffer[5];
                                        labelInstruction.Text = "0x" + (d1).ToString("X4") + " | 0x" + (d1).ToString("X4") + "       0b" + Convert.ToString(d1, 2);
                                        break;
                                    case 16:
                                        textBox2.AppendText("Got data: " + Encoding.ASCII.GetString(new byte[] { buffer[2] })+" ("+buffer[2]+")"+Environment.NewLine);
                                        break;
                                    case 25: //Hit breakpoint
                                        button20.BackColor = Color.Thistle;
                                        button20.Text = "Exit debugging";                                       
                                        break;
                                }
                            }
                            catch
                            {

                            }
                            
                        });
                       
                    }else
                    {
                        while (port.BytesToRead > 0) port.ReadByte();
                    }
                }

            }
        }
     
        private string getState(byte v)
        {
           switch(v)
            {
                case 0:
                    return "FETCH 1";
                case 1:
                    return "FETCH 2";
                case 2:
                    return "FETCH 3";
                case 3:
                    return "WORK 1";
                case 4:
                    return "WORK 2";
                case 5:
                    return "WORK 3";
                case 6:
                    return "STUCK";
                default:
                    return "UKNOWN";
            }
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

        Dictionary<int, int> lineToIndex = new Dictionary<int, int>();
        Dictionary<int, int> indexToLine = new Dictionary<int, int>();

        private void OnChanged(object sender, FileSystemEventArgs e)
        {
            this.Invoke((MethodInvoker)delegate () {

                if ((DateTime.Now - timeoutUntil).TotalMilliseconds < 0) return;

                timeoutUntil = DateTime.Now.AddSeconds(10);
                Thread.Sleep(2500);

                Console.WriteLine("File changed!");
                lines.Clear();
                using (StreamReader reader = new StreamReader(File.OpenRead(selectedFile.Text)))
                {
                    while (reader.EndOfStream == false) lines.Add(reader.ReadLine());
                }

                for (int i = 0; i < lines.Count; i++)
                {
                    int start = int.Parse(lines[i].Substring(3, 4), System.Globalization.NumberStyles.HexNumber);
                    lines[i] = lines[i].Substring(1, 2) + (start / 2).ToString("X4") + lines[i].Substring(7, lines[i].Length - 7 - 2);
                    int count = 0;
                    for (int j = 0; j < lines[i].Length; j += 2)
                    {
                        count += int.Parse(lines[i].ElementAt(j) + "" + lines[i].ElementAt(j + 1), System.Globalization.NumberStyles.HexNumber);
                    }
                    int a = (~count) + 1;
                    a = a & 0x000000FF;
                    lines[i] += (a).ToString("X2");
                    lines[i] = ":" + lines[i];
                }

                using (StreamWriter writer = new StreamWriter(outputFile.Text))
                {
                    foreach (string line in lines) writer.WriteLine(line);
                }

                if (File.Exists(selectedFile.Text.Replace(".hex", ".lss")))
                {
                    indexToLine.Clear();
                    lineToIndex.Clear();
                    listViewNF1.Items.Clear();
                    bool foundDiss = false; //Found the start of the interesting lines
                    using (StreamReader reader = new StreamReader(File.OpenRead(selectedFile.Text.Replace(".hex", ".lss"))))
                    {
                        while (reader.EndOfStream == false)
                        {
                            string line = reader.ReadLine();
                            string code = "";
                            if (line == "") continue;
                            if (line.Contains("00000000 <__vectors>:"))
                            {
                                foundDiss = true;
                                continue;
                            }
                            if (foundDiss == false) continue;
                            int linex = -1;
                            string num = line.Split(':')[0];
                            if (line.Contains(":\t"))
                            {

                                num = num.Replace(" ", "");
                                code = line.Split(':')[1];

                                if (int.TryParse(num, NumberStyles.HexNumber, CultureInfo.InvariantCulture, out linex))
                                {

                                }
                            }

                            ListViewItem toAdd = new ListViewItem(" ");
                            if (linex != -1) //Is a CODE line
                            {
                                addingItems = true;
                                toAdd.BackColor = Color.LightBlue;
                                toAdd.SubItems[0].Text = "0x" + linex.ToString("X");
                                toAdd.SubItems.Add(code.Replace("\t", "   "));
                                lineToIndex.Add(linex, listViewNF1.Items.Count);
                                indexToLine.Add( listViewNF1.Items.Count,linex);
                               
                            }
                            else
                            {
                                toAdd.BackColor = Color.DarkGray;
                                toAdd.SubItems.Add(line);
                            }

                            listViewNF1.Items.Add(toAdd);
                            //listView3.Items.Add(new ListViewItem("sd"));
                        }
                    }
                }

                addingItems = false;

                if (checkBox1.Checked == true) Programm();
            });

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

            programming = true;
            Thread.Sleep(1000);
            //Send handshake (Programming request)
            byte[] btt = new byte[] { 169 };
            port.Write(btt, 0, btt.Length);

            //Thread.Sleep(250);
            for (int i = 0; i < toSend.Count; i++)
            {
                byte[] btt2 = new byte[] { toSend[i] };
                port.Write(btt2, 0, btt2.Length);
                Thread.Sleep(10);
            }
            port.BaseStream.Flush();
            Thread.Sleep(2000);
            programming = false;
            //        port.Write(toSend.ToArray(), 0, toSend.Count);
        }

        private void button3_Click_1(object sender, EventArgs e)
        {
            OnChanged(null, null);
        }

 
        private void button6_Click(object sender, EventArgs e)
        {
            writeBytes(new byte[] { 42, 3, 0, 0, 0, 0 });
        }

        void writeBytes(byte[] bytes,bool skipProgramming=false)
        {
            if (programming && skipProgramming == false) return;

            for(int i=0;i<bytes.Length;i++)
            {
                port.Write(new byte[] { bytes[i] }, 0, 1);
            }
            port.BaseStream.Flush();
        }

        private void button7_Click(object sender, EventArgs e)
        {
            writeBytes(new byte[] { 42, 6, 4, 0, 0, 0 });
        }

    

        private void button8_Click(object sender, EventArgs e)
        {
            writeBytes(new byte[] { 42, 4, 1, 2, 3, 4 });
        }

        private void button9_Click(object sender, EventArgs e)
        {
            writeBytes(new byte[] { 42, 5, 0, 0, 0, 0 });
        }

        int count = 0;
        private void timer1_Tick(object sender, EventArgs e)
        {
            if(count%4==0) writeBytes(new byte[] { 42, 5, 0, 0, 0, 0 });
            if (count % 6 ==1) writeBytes(new byte[] { 42,14, 0, 0, 0, 0 });
            if (count % 5 == 2) writeBytes(new byte[] { 42, 15, 0, 0, 0, 0 });

            if (count==7)
            {
                button23.PerformClick();
                button5.PerformClick();
            }

            if(count%5==0)
            {
                List<int> got = new List<int>();
                List<int> gotIO = new List<int>();

                for(int i=0;i<listView1.Items.Count;i++)
                {
                    if(listView1.Items[i].Checked && got.Contains(i)==false)
                    {
                        toSend.Enqueue(new byte[] { 42, 12, (byte)i, 0, 0, 0 });
                        got.Add(i);
                        got.Add(i+1);
                        got.Add(i + 2);
                    }
                }

                for (int i = 0; i < listView2.Items.Count; i++)
                {
                    if (listView2.Items[i].Checked && gotIO.Contains(i) == false)
                    {
                        toSend.Enqueue(new byte[] { 42, 13, (byte)i, 0, 0, 0 });
                        gotIO.Add(i);
                        gotIO.Add(i + 1);
                        gotIO.Add(i + 2);
                    }
                }



              
            }
            if (toSend.Count > 0) writeBytes(toSend.Dequeue());
            count=( count+1)%50;
        }

 

        void setSpeed(int val)
        {
            byte[] bytes = BitConverter.GetBytes(val);
            writeBytes(new byte[] { 42, 7, bytes[0], bytes[1], bytes[2], bytes[3] });

            double number = (50000000.0/val) / 6.0;
            if(number>1000000)
            {
                labelMhz.Text = Math.Round(number/1000000, 2)+" MHz";
            }else
            if (number > 1000)
            {
                labelMhz.Text = Math.Round(number / 1000, 2) + " KHz";
            }else
            {

                labelMhz.Text = Math.Round(number , 2) + " Hz";
            }

        }
        private void button10_Click(object sender, EventArgs e)
        {
            setSpeed(M50 * 4);
        }

        int M50 = 50000000;

        private void button11_Click(object sender, EventArgs e)
        {
            setSpeed(M50 * 2);
        }

        private void button12_Click(object sender, EventArgs e)
        {
            setSpeed(M50 * 1);
        }

        private void button13_Click(object sender, EventArgs e)
        {
            setSpeed(M50 / 2);
        }

        private void button14_Click(object sender, EventArgs e)
        {
            setSpeed(M50 / 5);
        }

        private void button16_Click(object sender, EventArgs e)
        {
            setSpeed(M50 / 50);
        }

        private void button18_Click(object sender, EventArgs e)
        {
            setSpeed(M50 / 200);
        }

        private void button15_Click(object sender, EventArgs e)
        {
            setSpeed(M50 / 1000);
        }

        private void button17_Click(object sender, EventArgs e)
        {
            setSpeed(M50 / 10000);
        }

        private void button19_Click(object sender, EventArgs e)
        {
            setSpeed(3);
        }

        private void button20_Click(object sender, EventArgs e)
        {
            programming = true;
            Thread.Sleep(150);

            if (button20.Text.Contains("Enter"))
            {
                button20.BackColor = Color.Thistle;
                button20.Text = "Exit debugging";
                writeBytes(new byte[] { 42,8,0,0,0,0},true);
            }
            else
            {
                button20.BackColor = Color.Violet;
                button20.Text = "Enter debugging";
                writeBytes(new byte[] { 42, 9, 0, 0, 0, 0 },true);
            }

     
          

            Thread.Sleep(150);
            programming = false;
        }

        private void button10_Click_1(object sender, EventArgs e)
        {
            setSpeed(M50 / 11);
        }

        void addBytesToQueue(byte[] bytes)
        {
            toSend.Enqueue(bytes);
        }

        Queue<byte[]> toSend = new Queue<byte[]>();

        public bool programming { get; private set; }
        public bool addingItems { get; private set; }

        private void button21_Click(object sender, EventArgs e)
        {
            programming = true;
            Thread.Sleep(150);
            writeBytes(new byte[] { 42, 10, 1, 0, 0, 0 },true);
 
            Thread.Sleep(150);
            programming = false;
        }

        private void button22_Click(object sender, EventArgs e)
        {
            programming = true;
            Thread.Sleep(150);
            writeBytes(new byte[] { 42, 11, 6, 0, 0, 0 },true);
            Thread.Sleep(150);
            programming = false;
        }

        private void propertyGrid1_Click(object sender, EventArgs e)
        {

        }

        private void button23_Click(object sender, EventArgs e)
        {
            for(int i=0;i<=29;i+=3) //Normal
            {
                toSend.Enqueue(new byte[] { 42, 12, (byte)i, 0, 0, 0 });
         
            }
            toSend.Enqueue(new byte[] { 42, 12, 29, 0, 0, 0 });

        }

        private void button5_Click(object sender, EventArgs e)
        {
            for (int i = 0; i <= 61; i += 3) //IO
            {
                toSend.Enqueue(new byte[] { 42, 13, (byte)i, 0, 0, 0 });
            }
            toSend.Enqueue(new byte[] { 42, 13, 61, 0, 0, 0 });
        }

        private void label6_Click(object sender, EventArgs e)
        {

        }

        private void labelSP_Click(object sender, EventArgs e)
        {

        }

        public string getInstructionName(byte opcode)
        {
            if (opcode == 0) return "NOT FOUND";
            if (opcode == 1) return "LDI";
            if (opcode == 2) return "JMP";
            if (opcode == 3) return "CALL";
            if (opcode == 4) return "OUT";
            if (opcode == 5) return "RET";
            if (opcode == 7) return "RJUMP";
            if (opcode == 12) return "NOP";
            if (opcode == 16) return "IN";
            if (opcode == 22) return "BREQ";
            if (opcode == 23) return "BRCC";
            if (opcode == 25) return "PUSH";
            if (opcode == 26) return "POP";
            if (opcode == 27) return "MOV";
            if (opcode == 9) return "EOR";
            if (opcode == 6) return "CLI";
            if (opcode == 24) return "ANDI";
            if (opcode == 43) return "LSR";
            if (opcode == 9) return "SUBI";
            if (opcode == 10) return "SUBCI";
            if (opcode == 11) return "BRNE";
            if (opcode == 15) return "SEI";
            if (opcode == 38) return "SBIW";
            if (opcode == 44) return "SCB";
            return "UKNOWN";
        }

        private void pictureBox1_Paint(object sender, PaintEventArgs e)
        {
            Brush brush = Brushes.Black;
            int width = 28;
            for (int i = 0; i < 6; i++)
            {
                if ((lastPort5 & (1 << (8 - (i+2)) - 1)) != 0)
                {
                    brush = Brushes.Green;
                }
                else
                {
                    brush = Brushes.Red;
                }
                e.Graphics.FillRectangle(brush, new RectangleF(i * width, 0, width-2, width-2));
            }


            for (int i=0;i<8;i++)
            {
                if((lastPort11 & (1 << (8-i) - 1)) != 0)
                {
                    brush = Brushes.Green;
                }else
                {
                    brush = Brushes.Red;
                }
                e.Graphics.FillRectangle(brush, new RectangleF((width * 6)+i* width, 0, width-2, width-2));
            }
        }

        private void timer2_Tick(object sender, EventArgs e)
        {
            pictureBox1.Invalidate();
        }

        private void button8_Click_1(object sender, EventArgs e)
        {
            textBox2.Clear();
        }

        private void button7_Click_1(object sender, EventArgs e)
        {
            foreach(var chara in textBox1.Text)
            {
                toSend.Enqueue(new byte[] { 42, 16, (byte)chara, 0, 0, 0 });
                Thread.Sleep(10);
            }

          
            textBox2.AppendText(" --- Sent data: " +textBox1.Text+Environment.NewLine);
            textBox1.Text = "";
        }

        private void listViewNF1_ItemChecked(object sender, ItemCheckedEventArgs e)
        {
            if (addingItems) return;

            bool set1=false, set2=false;
            byte[] byts=new byte[] { 42, 17, 0, 0, 0, 0 };

            for(int i=0;i<listViewNF1.Items.Count;i++)
            {
                if(listViewNF1.Items[i].Checked)
                {
                    if(set1==false)
                    {
                        byte[] bytes = BitConverter.GetBytes(indexToLine[i]/2);
                        byts[2] = bytes[0];
                        byts[3] = bytes[1];
                        set1 = true;
                    }else if(set2==false)
                    {
                        byte[] bytes = BitConverter.GetBytes(indexToLine[i] / 2);
                        byts[4] = bytes[0];
                        byts[5] = bytes[1];
                        set2 = true;
                    }
                }
            }

            programming = true;
            Thread.Sleep(100);
            writeBytes(byts,true);
            Thread.Sleep(100);
            programming = false;
           

        }
    }

/*
cpi=13,
cpc=14,
ori=17,
ld=18,
lds=19,
st=20,
sts=21,
lpmII=28,
movw=29,
Xand=30,
cpse=31,
Xor=32,
com=33,
adiw=34,
adc=35,
reti=36,
add=37,
sbiw=38,
stXP=39,
stX=40,
ldZ=41,
stZ=42,

skip1=156,*/
}
