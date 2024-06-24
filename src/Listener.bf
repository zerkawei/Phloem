using System;
using System.Threading;
using System.Collections;

using internal Phloem;
namespace Phloem;

public interface IListener<T> : IEnumerable<Message<T>> where T : enum
{
	public struct Enumerator : IEnumerator<Message<T>>
	{
		private IListener<T> listener;
		private Message<T> cur;

		public this(IListener<T> listener)
		{
			this.listener = listener;
			this.cur      = null;
		}

		public Result<Message<T>> GetNext() mut
		{
			cur?.ReleaseRef();
			let res = listener.Next();
		    if(res case .Ok(var val)) { cur = val; }
			return res;
		}
	}

	public Result<Message<T>> Next();
}

public class Listener<T> : IListener<T> where T : enum
{
	private IChannel<T, Self> channel;

	public this(IChannel<T, Self> channel)
	{
		this.channel = channel;
	}

	[Inline] public Result<Message<T>> Next() => channel.GetNextFor(this);
	public IListener<T>.Enumerator GetEnumerator() => IListener<T>.Enumerator(this);
}

public class BroadcastListener<T> : IListener<T> where T : enum, IHashable
{
	internal BroadcastChannel<T> channel;
	internal int sequenceNumber;
	internal IFilter<T> filter ~ if(filter != null) delete filter;

	public this(BroadcastChannel<T> channel, IFilter<T> filter = null)
	{
		this.filter  = filter;
		channel.Register(this);
	}

	[Inline] public Result<Message<T>> Next() => channel.GetNextFor(this);
	public IListener<T>.Enumerator GetEnumerator() => IListener<T>.Enumerator(this);
}