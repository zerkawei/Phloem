using System;
using System.Collections;
namespace Phloem;

public interface IFilter<T> where T : enum
{
	bool Accepts(Message<T> message);
}

public class TypeSetFilter<T> : IFilter<T> where T : enum, IHashable
{
	public HashSet<T> acceptedTypes = new .() ~ delete _;

	public this(params T[] types)
	{
		for(let t in types)
		{
			acceptedTypes.Add(t);
		}
	}

	public bool Accepts(Message<T> message) => acceptedTypes.Contains(message.Type);
}
