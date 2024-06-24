using System;
using System.Collections;
using System.Threading;

using internal Phloem;
namespace Phloem;

internal interface IChannel<T, L> where T : enum
								  where L : IListener<T>
{
	void Post(Message<T> message);
	Result<Message<T>> GetNextFor(L listener);
}

public class BroadcastChannel<T> : IChannel<T, BroadcastListener<T>> where T : enum, IHashable
{
	private struct Item : this(Message<T> Message, int UnreadCount);

	private Queue<Item> internalQueue = new .();
	private Monitor     lock          = new .() ~ delete _;
	private int         listenerCount;
	private int         headSequenceNumber;

	public Event<delegate void(Message<T> message)> OnMessage = .() ~ _.Dispose();

	public ~this()
	{
		for(let msg in internalQueue)
		{
			msg.Message.ReleaseRef();
		}
		delete internalQueue;
	}

	public void Register(BroadcastListener<T> listener)
	{
		listener.channel = this;
		listener.sequenceNumber = headSequenceNumber + internalQueue.Count;
		Interlocked.Increment(ref listenerCount);
	}
	public void Unregister(BroadcastListener<T> listener)
	{
		for(let msg in listener) {}
		Interlocked.Decrement(ref listenerCount);
		listener.channel = null;
	}

	public void Post(Message<T> message)
	{
		OnMessage(message);
		if(listenerCount < 1)
		{
			message.ReleaseRef();
		}
		else
		{
			internalQueue.Add(.(message, listenerCount));
		}
	}
	public Result<Message<T>> GetNextFor(BroadcastListener<T> listener)
	{
		for(var idx = listener.sequenceNumber - headSequenceNumber;
			idx >= 0 && idx < internalQueue.Count;
			idx = listener.sequenceNumber - headSequenceNumber)
		{
			listener.sequenceNumber++;
			var item = ref internalQueue[idx];

			if(listener.filter == null || listener.filter.Accepts(item.Message))
			{
				item.Message.AddRef();
				Read(ref item);
				return item.Message;
			}
			
			Read(ref item);
		}
		return .Err;
	}
	
	private void Read(ref Item item)
	{
		lock.Enter();
		if(item.UnreadCount == 1)
		{
		    // If we're the last listener to take the message, pop it from the queue
			internalQueue.PopFront();
			item.Message.ReleaseRef();
			Interlocked.Increment(ref headSequenceNumber);
		}
		else
		{
			Interlocked.Decrement(ref item.UnreadCount);
		}
		lock.Exit();
	}
}

public class QueueChannel<T> : IChannel<T, Listener<T>> where T : enum
{
	private Queue<Message<T>> internalQueue = new .();

	public Event<delegate void(Message<T> message)> OnMessage = .() ~ _.Dispose();

	public ~this()
	{
		for(let msg in internalQueue)
		{
			msg.ReleaseRef();
		}
		delete internalQueue;
	}

	public void Post(Message<T> message)
	{
		OnMessage(message);
		internalQueue.Add(message);
	}
	public Result<Message<T>> GetNextFor(Listener<T> listener) => (internalQueue.Count > 0) ? internalQueue.PopBack() : .Err;
}