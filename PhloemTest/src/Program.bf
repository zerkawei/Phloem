using Phloem;
using System;

namespace PhloemTest;

public class Program
{
	public enum MsgType
	{
		Log,
		Warning,
		Error
	}	

	public static void Main()
	{
		let bChannel = scope BroadcastChannel<MsgType>();

		bChannel.Post(new .(.Log)); // Message dropped because no listeners

		let bList1 = scope BroadcastListener<MsgType>(bChannel);
		let bList2 = scope BroadcastListener<MsgType>(bChannel, new TypeSetFilter<MsgType>(.Error));

		bChannel.Post(new .(.Log));
		bChannel.Post(new .(.Error));

		let bList3 = scope BroadcastListener<MsgType>(bChannel);

		bChannel.Post(new .(.Warning));

		Console.WriteLine("bList1 has");
		for(let m in bList1) { Console.WriteLine(m.Type); }

		Console.WriteLine("bList2 has");
		for(let m in bList2) { Console.WriteLine(m.Type); }

		Console.WriteLine("bList3 has");
		for(let m in bList3) { Console.WriteLine(m.Type); }

		Console.Read();

		let qChannel = scope QueueChannel<MsgType>();

		qChannel.Post(new .(.Log)); // Message is queued

		let qList1 = scope Listener<MsgType>(qChannel);
		let qList2 = scope Listener<MsgType>(qChannel);

		qChannel.Post(new .(.Error));

		Console.WriteLine("qList1 has");
		for(let m in qList1) { Console.WriteLine(m.Type); }

		qChannel.Post(new .(.Warning));

		Console.WriteLine("qList2 has");
		for(let m in qList2) { Console.WriteLine(m.Type); }

		Console.Read();
	}
}