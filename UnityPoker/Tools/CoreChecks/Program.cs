using Poks.Core;
int checks=0;
void Check(bool ok,string message){checks++;if(!ok)throw new Exception(message);}
int C(int rank,int suit=0)=>(rank-2)+13*suit;
long E(params int[] c)=>Cards.Evaluate(c);
Check(E(C(14),C(2,1),C(3,2),C(4,3),C(5)) < E(C(2),C(3,1),C(4,2),C(5,3),C(6)),"wheel below six-high");
Check(Cards.Description(E(C(10),C(11),C(12),C(13),C(14)))=="Quinte flush","royal category");
Check(E(C(14),C(14,1),C(2),C(3),C(4))>E(C(13),C(13,1),C(14),C(12),C(11)),"pair ranks");
Check(E(C(2),C(4),C(6),C(8),C(10),C(12),C(14))==E(C(6),C(8),C(10),C(12),C(14)),"best five from seven");
var opening=new Tournament("Test",42);opening.StartHand();
Check(opening.Actor==0&&opening.Dealer==0,"three-handed button first preflop");
Check(!opening.Act(Move.Raise,21)&&opening.CurrentBet==20,"reject under-minimum raise");
Check(opening.Act(Move.Call)&&opening.Act(Move.Call)&&opening.Actor==2,"big blind option");
Check(opening.Act(Move.Call)&&opening.Board.Count==3&&opening.Actor==1,"flop starts left of dealer");
for(int seed=1;seed<=100;seed++) {
 var g=new Tournament("Test",seed,100);var rng=new Random(seed);int actions=0;
 while(!g.Complete&&g.Hand<400) {
  Check(g.StartHand(),"start hand");
  while(!g.Finished&&actions++<40000) {
   int a=g.Actor;Check(a>=0&&g.Seats[a].Stack>0,"actor solvent");
   Check(g.Seats.Sum(p=>p.Stack)+g.Pot==300,"chip conservation during hand");
   var visible=g.Seats.SelectMany(p=>p.Hole).Concat(g.Board).ToArray();Check(visible.Distinct().Count()==visible.Length,"no duplicate cards");
   bool accepted;
   double r=rng.NextDouble();
   if(g.CanRaise(a)&&r<.36)accepted=g.Act(Move.Raise,g.MaxRaise(a));
   else if(g.ToCall(a)>0&&r>.88)accepted=g.Act(Move.Fold);
   else accepted=g.Act(Move.Call);
   Check(accepted,"legal action accepted");
  }
  Check(g.Finished,"hand terminated");Check(g.Seats.Sum(p=>p.Stack)==300,"chips after payout");
 }
 Check(g.Complete,"tournament terminated");Check(g.Seats[g.Winner].Stack==300,"winner receives chips");
}
var shortRaise=new Tournament("Short",22);shortRaise.Seats[1].Stack=50;shortRaise.StartHand();
Check(shortRaise.Act(Move.Raise,40)&&shortRaise.Act(Move.Raise,50)&&shortRaise.Act(Move.Call),"short all-in actions");
Check(shortRaise.Actor==0&&!shortRaise.CanRaise(0)&&!shortRaise.Act(Move.Raise,100),"short all-in does not reopen");
Check(shortRaise.Act(Move.Call)&&shortRaise.Street==Street.Flop,"call short all-in and advance");
var headsUp=new Tournament("HU",22);headsUp.Seats[1].Stack=0;headsUp.StartHand();
Check(headsUp.Actor==0&&headsUp.Seats[0].Bet==10&&headsUp.Seats[2].Bet==20,"heads-up blinds");
headsUp.Act(Move.Call);headsUp.Act(Move.Call);Check(headsUp.Actor==2,"heads-up postflop order");
for(int seed=1;seed<=80;seed++) {
 var side=new Tournament("Side",seed);side.Seats[0].Stack=35;side.Seats[1].Stack=90;side.Seats[2].Stack=175;side.StartHand();
 Check(side.Act(Move.Raise,35)&&side.Act(Move.Raise,90)&&side.Act(Move.Call),"side-pot all-in sequence");
 Check(side.Finished,"all-in runs out board");
 var scores=side.Seats.Select(p=>Cards.Evaluate(p.Hole.Concat(side.Board).ToArray())).ToArray();int[] expected={0,0,85};
 foreach(var pot in new[]{(105,new[]{0,1,2}),(110,new[]{1,2})}) {
  long best=pot.Item2.Max(i=>scores[i]);var winners=pot.Item2.Where(i=>scores[i]==best).OrderBy(i=>(i-side.Dealer+2)%3).ToArray();
  for(int j=0;j<winners.Length;j++)expected[winners[j]]+=pot.Item1/winners.Length+(j<pot.Item1%winners.Length?1:0);
 }
 Check(expected.SequenceEqual(side.Seats.Select(p=>p.Stack)),"exact eligible side-pot payouts and odd chips");
}
if(args.Contains("--exhaustive")) {
 long[] counts=new long[9];
 for(int a=0;a<48;a++)for(int b=a+1;b<49;b++)for(int c=b+1;c<50;c++)for(int d=c+1;d<51;d++)for(int e=d+1;e<52;e++)counts[E(a,b,c,d,e)/759375]++;
 Check(counts.SequenceEqual(new long[]{1302540,1098240,123552,54912,10200,5108,3744,624,40}),"all 2598960 five-card hands category frequencies");
 Console.WriteLine("PASS: exhaustive 2,598,960 five-card hand categories.");
}
var ai=new Tournament("Humain",71,80);ai.StartHand();int n=0;
while(!ai.Finished&&n++<100){if(ai.Actor==0)Check(ai.Act(Move.Call),"human call");else Check(ai.ActAI(),"AI legal move");}
Check(ai.Finished,"AI completes hand");
Console.WriteLine($"PASS: {checks} checks; 100 complete three-player tournaments; evaluator and AI smoke checks.");
