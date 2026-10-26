using System;
using System.Collections.Generic;
using System.Linq;

namespace Poks.Core
{
    public enum Move { Fold, Call, Raise }
    public enum Street { Preflop, Flop, Turn, River, Showdown }
    [Serializable] public sealed class Seat
    {
        public string Name;
        public int Stack, Bet, Committed;
        public bool Folded;
        public int[] Hole = new int[0];
        public Seat(string name,int stack){Name=name;Stack=stack;}
    }
    // No Unity dependencies. One state transition per accepted action; no coroutine mutates these rules.
    public sealed class Tournament
    {
        readonly Random random;
        readonly List<int> deck=new List<int>();
        readonly HashSet<int> pending=new HashSet<int>();
        readonly int[] lastActionBet={-1,-1,-1};
        public Seat[] Seats {get;}
        public List<int> Board {get;} = new List<int>();
        public List<string> Log {get;} = new List<string>();
        public Street Street {get;private set;}
        public int Dealer {get;private set;} = -1;
        public int Actor {get;private set;} = -1;
        public int CurrentBet {get;private set;}
        public int LastFullRaise {get;private set;}
        public int Hand {get;private set;}
        public int SmallBlind => 10 * (1 << Math.Min(6,(Math.Max(1,Hand)-1)/8));
        public int BigBlind => SmallBlind*2;
        public bool Finished {get;private set;} = true;
        public bool Complete => Finished && Seats.Count(p=>p.Stack>0)==1;
        public int Winner => Complete?Array.FindIndex(Seats,p=>p.Stack>0):-1;
        public int Pot => Seats.Sum(p=>p.Committed);
        public string Result {get;private set;} = "";
        public Tournament(string name, int seed=0, int stack=1000)
        {
            if(stack<=0)throw new ArgumentOutOfRangeException(nameof(stack));
            Seats=new[]{new Seat(name,stack),new Seat("Adrien de Valmont",stack),new Seat("Éléonore Moreau",stack)};
            random=seed==0?new Random():new Random(seed);
        }
        int Next(int from,Func<Seat,bool> valid)
        {
            for(int k=1;k<=3;k++){int i=(from+k+3)%3;if(valid(Seats[i]))return i;}
            return -1;
        }
        int Draw(){int c=deck[deck.Count-1];deck.RemoveAt(deck.Count-1);return c;}
        void Pay(int i,int amount){amount=Math.Min(amount,Seats[i].Stack);Seats[i].Stack-=amount;Seats[i].Bet+=amount;Seats[i].Committed+=amount;}
        void Add(string s){Log.Add(s);if(Log.Count>120)Log.RemoveAt(0);}
        public bool StartHand()
        {
            if(!Finished||Seats.Count(p=>p.Stack>0)<2)return false;
            Hand++;Finished=false;Board.Clear();Result="";Street=Street.Preflop;CurrentBet=0;pending.Clear();
            for(int i=0;i<3;i++){var p=Seats[i];p.Bet=p.Committed=0;p.Folded=p.Stack==0;p.Hole=new int[0];lastActionBet[i]=-1;}
            Dealer=Next(Dealer,p=>p.Stack>0);deck.Clear();deck.AddRange(Enumerable.Range(0,52));
            for(int i=51;i>0;i--){int j=random.Next(i+1);int t=deck[i];deck[i]=deck[j];deck[j]=t;}
            int sb=Seats.Count(p=>p.Stack>0)==2?Dealer:Next(Dealer,p=>p.Stack>0);
            int bb=Next(sb,p=>p.Stack>0);
            // Deal clockwise, one card each round, starting left of the button.
            var holes=new List<int>[3];for(int i=0;i<3;i++)holes[i]=new List<int>();
            for(int round=0;round<2;round++)for(int k=1;k<=3;k++){int i=(Dealer+k)%3;if(!Seats[i].Folded)holes[i].Add(Draw());}
            for(int i=0;i<3;i++)Seats[i].Hole=holes[i].ToArray();
            Pay(sb,SmallBlind);Pay(bb,BigBlind);CurrentBet=BigBlind;LastFullRaise=BigBlind;
            for(int i=0;i<3;i++)if(!Seats[i].Folded&&Seats[i].Stack>0)pending.Add(i);
            Add($"Main {Hand} · blindes {SmallBlind}/{BigBlind}");
            Actor=Next(bb,p=>!p.Folded&&p.Stack>0);AdvanceIfNeeded();return true;
        }
        public int ToCall(int i)=>Math.Max(0,CurrentBet-Seats[i].Bet);
        public int MinRaise => CurrentBet+LastFullRaise;
        public int MaxRaise(int i)=>Seats[i].Bet+Seats[i].Stack;
        public bool CanRaise(int i) => !Finished&&i==Actor&&Seats[i].Stack>ToCall(i)&&
            (lastActionBet[i]<0||CurrentBet-lastActionBet[i]>=LastFullRaise)&&
            Seats.Where((p,j)=>j!=i&&!p.Folded&&p.Stack>0).Any();
        public bool Act(Move move,int target=0)
        {
            if(Finished||Actor<0||!pending.Contains(Actor))return false;
            int i=Actor;var p=Seats[i];
            if(move==Move.Raise) {
                if(!CanRaise(i)||target<=CurrentBet||target>MaxRaise(i)||(target<MinRaise&&target!=MaxRaise(i)))return false;
                int increase=target-CurrentBet;Pay(i,target-p.Bet);CurrentBet=target;
                if(increase>=LastFullRaise){LastFullRaise=increase;pending.Clear();}
                for(int j=0;j<3;j++)if(j!=i&&!Seats[j].Folded&&Seats[j].Stack>0&&Seats[j].Bet<CurrentBet)pending.Add(j);
                Add($"{p.Name} relance à {target}"+(p.Stack==0?" · tapis":""));
            } else if(move==Move.Fold){p.Folded=true;Add(p.Name+" passe");}
            else {int call=Math.Min(ToCall(i),p.Stack);Pay(i,call);Add(p.Name+(call==0?" : parole":$" suit {call}")+(p.Stack==0?" · tapis":""));}
            lastActionBet[i]=CurrentBet;pending.Remove(i);
            Actor=Next(i,s=>!s.Folded&&s.Stack>0&&pending.Contains(Array.IndexOf(Seats,s)));
            AdvanceIfNeeded();return true;
        }
        void AdvanceIfNeeded()
        {
            if(Seats.Count(p=>!p.Folded)==1){Settle();return;}
            pending.RemoveWhere(i=>Seats[i].Folded||Seats[i].Stack==0);
            // A sole solvent player must answer a bet, but may not bet into opponents already all-in.
            if(Seats.Count(p=>!p.Folded&&p.Stack>0)<=1)
                pending.RemoveWhere(i=>Seats[i].Bet>=CurrentBet);
            if(pending.Count>0) {
                if(Actor<0||!pending.Contains(Actor))Actor=Next(Dealer,s=>pending.Contains(Array.IndexOf(Seats,s)));
                return;
            }
            if(Street==Street.River){Settle();return;}
            foreach(var p in Seats)p.Bet=0;
            CurrentBet=0;LastFullRaise=BigBlind;
            for(int i=0;i<3;i++)lastActionBet[i]=-1;
            Draw(); // burn
            if(Street==Street.Preflop){Street=Street.Flop;Board.Add(Draw());Board.Add(Draw());Board.Add(Draw());}
            else {Street=(Street)((int)Street+1);Board.Add(Draw());}
            Add(Street+" · "+string.Join(" ",Board.Select(Cards.Label)));
            for(int i=0;i<3;i++)if(!Seats[i].Folded&&Seats[i].Stack>0)pending.Add(i);
            Actor=Next(Dealer,p=>!p.Folded&&p.Stack>0);
            if(Seats.Count(p=>!p.Folded&&p.Stack>0)<=1){pending.Clear();AdvanceIfNeeded();}
        }
        void Settle()
        {
            var alive=Enumerable.Range(0,3).Where(i=>!Seats[i].Folded).ToArray();
            var scores=new Dictionary<int,long>();
            if(alive.Length>1)foreach(int i in alive)scores[i]=Cards.Evaluate(Seats[i].Hole.Concat(Board).ToArray());
            int previous=0;var payouts=new int[3];
            foreach(int level in Seats.Select(p=>p.Committed).Where(x=>x>0).Distinct().OrderBy(x=>x)) {
                int amount=(level-previous)*Seats.Count(p=>p.Committed>=level);previous=level;
                var eligible=alive.Where(i=>Seats[i].Committed>=level).ToArray();
                if(eligible.Length==0){ // Only unmatched folded excess is possible in malformed external state; reject it.
                    throw new InvalidOperationException("Pot without eligible player");
                }
                long best=alive.Length==1?0:eligible.Max(i=>scores[i]);
                var winners=eligible.Where(i=>alive.Length==1||scores[i]==best).OrderBy(i=>(i-Dealer+2)%3).ToArray();
                for(int j=0;j<winners.Length;j++)payouts[winners[j]]+=amount/winners.Length+(j<amount%winners.Length?1:0);
            }
            var result=new List<string>();
            for(int i=0;i<3;i++)if(payouts[i]>0){Seats[i].Stack+=payouts[i];result.Add($"{Seats[i].Name} : +{payouts[i]}"+(scores.ContainsKey(i)?" · "+Cards.Description(scores[i]):""));}
            Result=string.Join("\n",result);Add(Result);foreach(var p in Seats){p.Committed=0;p.Bet=0;}
            Finished=true;Actor=-1;pending.Clear();Street=Street.Showdown;
        }
        // Monte-Carlo equity samples only the AI's hole cards and public board, never opponents' real cards.
        public bool ActAI()
        {
            if(Finished||Actor<=0)return false;
            int i=Actor;var p=Seats[i];var known=new HashSet<int>(p.Hole.Concat(Board));
            int[] unknown=Enumerable.Range(0,52).Where(c=>!known.Contains(c)).ToArray();
            double equity=0;const int trials=70;int opponents=Seats.Count(s=>!s.Folded)-1;
            for(int t=0;t<trials;t++) {
                var pool=(int[])unknown.Clone();for(int k=0;k<12;k++){int j=random.Next(k,pool.Length);int tmp=pool[k];pool[k]=pool[j];pool[j]=tmp;}
                int at=0;var board=new List<int>(Board);while(board.Count<5)board.Add(pool[at++]);
                long own=Cards.Evaluate(p.Hole.Concat(board).ToArray());int ties=1;bool lost=false;
                for(int o=0;o<opponents;o++){long other=Cards.Evaluate(new[]{pool[at++],pool[at++]}.Concat(board).ToArray());if(other>own)lost=true;if(other==own)ties++;}
                if(!lost)equity+=1.0/ties;
            }
            equity/=trials;int call=ToCall(i);double price=call/(double)Math.Max(1,Pot+call);
            if(call>0&&equity<price+.04&&random.NextDouble()>.10)return Act(Move.Fold);
            if(CanRaise(i)&&(equity>.65||random.NextDouble()<.09)) {
                int target=Math.Min(MaxRaise(i),Math.Max(MinRaise,CurrentBet+Math.Max(BigBlind,Pot/2)));
                return Act(Move.Raise,target);
            }
            return Act(Move.Call);
        }
    }
}
