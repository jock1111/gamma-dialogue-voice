using System;
using System.Collections.Generic;
using System.IO;

// Anomaly reads gain from the X-Ray binary user comment in the Vorbis header.
// Keeping the audio packets intact makes repeated volume changes lossless.
public static class DialogueOggVolume
{
    private static readonly uint[] CrcTable = CreateCrcTable();

    private static uint[] CreateCrcTable()
    {
        var table = new uint[256];
        for (uint value = 0; value < table.Length; value++)
        {
            uint crc = value << 24;
            for (int bit = 0; bit < 8; bit++)
                crc = (crc << 1) ^ ((crc & 0x80000000u) != 0 ? 0x04C11DB7u : 0u);
            table[value] = crc;
        }
        return table;
    }

    private static int ReadPage(byte[] data, int start)
    {
        if (start < 0 || start > data.Length - 27 ||
            data[start] != 'O' || data[start + 1] != 'g' ||
            data[start + 2] != 'g' || data[start + 3] != 'S')
            throw new InvalidDataException("Invalid Ogg page.");

        int count = data[start + 26];
        int table = start + 27;
        int end = table + count;
        if (end > data.Length)
            throw new InvalidDataException("Truncated Ogg segment table.");
        for (int i = table; i < table + count; i++)
            end += data[i];
        if (end > data.Length)
            throw new InvalidDataException("Truncated Ogg page.");
        return end;
    }

    private static int LocateGain(byte[] data, out int page, out int end)
    {
        page = ReadPage(data, 0);
        end = ReadPage(data, page);
        int packet = page + 27 + data[page + 26];
        int packetSize = 0;
        bool complete = false;
        for (int i = page + 27; i < packet; i++)
        {
            packetSize += data[i];
            if (data[i] < 255)
            {
                complete = true;
                break;
            }
        }
        byte[] signature = { 3, (byte)'v', (byte)'o', (byte)'r', (byte)'b', (byte)'i', (byte)'s' };
        if (!complete || packetSize < 44 || packetSize > end - packet)
            throw new InvalidDataException("Expected a complete Vorbis comment packet.");
        for (int i = 0; i < signature.Length; i++)
            if (data[packet + i] != signature[i])
                throw new InvalidDataException("Expected a Vorbis comment packet.");

        int vendor = BitConverter.ToInt32(data, packet + 7);
        if (vendor < 0 || vendor > packetSize - 44)
            throw new InvalidDataException("Invalid Vorbis vendor length.");
        int fields = packet + 11 + vendor;
        if (BitConverter.ToInt32(data, fields) != 1 ||
            BitConverter.ToInt32(data, fields + 4) != 24 ||
            BitConverter.ToInt32(data, fields + 8) != 3)
            throw new InvalidDataException("Expected a version 3 X-Ray sound comment.");
        return fields + 20;
    }

    public static float ReadGain(string path)
    {
        byte[] data = File.ReadAllBytes(path);
        int start, end;
        return BitConverter.ToSingle(data, LocateGain(data, out start, out end));
    }

    public static int ApplyDirectory(string directory, int percent)
    {
        if (percent < 0 || percent > 200)
            throw new ArgumentOutOfRangeException("percent");
        float gain = percent / 100f;
        int changed = 0;
        foreach (string file in Directory.EnumerateFiles(directory, "*.ogg", SearchOption.TopDirectoryOnly))
        {
            try
            {
                if (ApplyFile(file, gain)) changed++;
            }
            catch (Exception error)
            {
                throw new IOException("Could not set dialogue volume in " + file, error);
            }
        }
        return changed;
    }

    private static bool ApplyFile(string path, float gain)
    {
        byte[] data = File.ReadAllBytes(path);
        int start, end;
        int offset = LocateGain(data, out start, out end);
        if (BitConverter.ToSingle(data, offset) == gain)
            return false;
        Buffer.BlockCopy(BitConverter.GetBytes(gain), 0, data, offset, 4);
        Array.Clear(data, start + 22, 4);

        uint crc = 0;
        for (int i = start; i < end; i++)
            crc = (crc << 8) ^ CrcTable[((crc >> 24) ^ data[i]) & 255];
        Buffer.BlockCopy(BitConverter.GetBytes(crc), 0, data, start + 22, 4);
        string temporary = path + ".volume-" + Guid.NewGuid().ToString("N");
        try
        {
            File.WriteAllBytes(temporary, data);
            File.Replace(temporary, path, null);
        }
        finally
        {
            if (File.Exists(temporary)) File.Delete(temporary);
        }
        return true;
    }
}
