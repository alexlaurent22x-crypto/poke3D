using System;
using System.Linq;
using NUnit.Framework;
using Poks.Core;

namespace Poks.Tests
{
    public sealed class RuleTests
    {
        [Test] public void ShortAllInDoesNotReopenRaise()
        {
            var g=new Tournament("Test",22);g.Seats[1].Stack=50;g.StartHand();
            Assert.IsTrue(g.Act(Move.Raise,40));Assert.IsTrue(g.Act(Move.Raise,50));Assert.IsTrue(g.Act(Move.Call));
            Assert.AreEqual(0,g.Actor);Assert.IsFalse(g.CanRaise(0));Assert.IsFalse(g.Act(Move.Raise,100));Assert.IsTrue(g.Act(Move.Call));
            Assert.AreEqual(Street.Flop,g.Street);
        }
        [Test] public void HeadsUpButtonPostsSmallBlindAndActsFirst()
        {
            var g=new Tournament("Test",22);g.Seats[1].Stack=0;g.StartHand();
            Assert.AreEqual(0,g.Dealer);Assert.AreEqual(0,g.Actor);Assert.AreEqual(10,g.Seats[0].Bet);Assert.AreEqual(20,g.Seats[2].Bet);
            g.Act(Move.Call);g.Act(Move.Call);Assert.AreEqual(2,g.Actor);
        }
        [Test] public void SidePotsPayOnlyEligibleHands()
        {
            for(int seed=1;seed<=80;seed++) {
                var g=new Tournament("Test",seed);g.Seats[0].Stack=35;g.Seats[1].Stack=90;g.Seats[2].Stack=175;g.StartHand();
                Assert.IsTrue(g.Act(Move.Raise,35));Assert.IsTrue(g.Act(Move.Raise,90));Assert.IsTrue(g.Act(Move.Call));
                Assert.IsTrue(g.Finished);var scores=g.Seats.Select(p=>Cards.Evaluate(p.Hole.Concat(g.Board).ToArray())).ToArray();
                int[] expected={0,0,85};
                Distribute(105,new[]{0,1,2});Distribute(110,new[]{1,2});
                CollectionAssert.AreEqual(expected,g.Seats.Select(p=>p.Stack).ToArray());
                void Distribute(int pot,int[] eligible) {
                    long best=eligible.Max(i=>scores[i]);var winners=eligible.Where(i=>scores[i]==best).OrderBy(i=>(i-g.Dealer+2)%3).ToArray();
                    for(int i=0;i<winners.Length;i++)expected[winners[i]]+=pot/winners.Length+(i<pot%winners.Length?1:0);
                }
            }
        }
        [Test] public void EveryFiveCardHandHasExpectedCategoryFrequencies()
        {
            // Known complete combinatorial distribution, independent of the evaluator implementation.
            long[] counts=new long[9];
            for(int a=0;a<48;a++)for(int b=a+1;b<49;b++)for(int c=b+1;c<50;c++)for(int d=c+1;d<51;d++)for(int e=d+1;e<52;e++)
                counts[Cards.Evaluate(new[]{a,b,c,d,e})/759375]++;
            CollectionAssert.AreEqual(new long[]{1302540,1098240,123552,54912,10200,5108,3744,624,40},counts);
        }
    }
}
