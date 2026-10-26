using System;
using System.Collections.Generic;
using System.Linq;

namespace Poks.Core
{
    // IDs 0..51: rank 2..Ace, suit clubs/diamonds/hearts/spades.
    public static class Cards
    {
        public static int Rank(int c) => c % 13 + 2;
        public static int Suit(int c) => c / 13;
        public static string Label(int c) => "23456789TVDRA"[c % 13] + new[] {"♣", "♦", "♥", "♠"}[Suit(c)];
        public static readonly string[] Categories = {"Carte haute", "Paire", "Deux paires", "Brelan", "Quinte", "Couleur", "Full", "Carré", "Quinte flush"};
        public static string Description(long score) => Categories[(int)(score / 759375)]; // 15^5
        public static long Evaluate(IReadOnlyList<int> cards)
        {
            if (cards.Count < 5 || cards.Count > 7 || cards.Distinct().Count() != cards.Count || cards.Any(c => c < 0 || c >= 52))
                throw new ArgumentException("Five to seven distinct card IDs required");
            long best = 0;
            for (int a=0;a<cards.Count-4;a++) for (int b=a+1;b<cards.Count-3;b++)
            for (int c=b+1;c<cards.Count-2;c++) for (int d=c+1;d<cards.Count-1;d++)
            for (int e=d+1;e<cards.Count;e++) best = Math.Max(best, Five(cards[a],cards[b],cards[c],cards[d],cards[e]));
            return best;
        }
        static long Score(int category, params int[] ranks)
        {
            long n=category;
            for (int i=0;i<5;i++) n=n*15+(i<ranks.Length?ranks[i]:0);
            return n;
        }
        static long Five(params int[] cards)
        {
            int[] r=cards.Select(Rank).OrderByDescending(x=>x).ToArray();
            bool flush=cards.All(c=>Suit(c)==Suit(cards[0]));
            var unique=r.Distinct().ToArray(); int straight=0;
            if(unique.Length==5) {
                if(unique[0]-unique[4]==4) straight=unique[0];
                else if(unique.SequenceEqual(new[]{14,5,4,3,2})) straight=5;
            }
            var groups=r.GroupBy(x=>x).OrderByDescending(x=>x.Count()).ThenByDescending(x=>x.Key).ToArray();
            if(flush&&straight>0)return Score(8,straight);
            if(groups[0].Count()==4)return Score(7,groups[0].Key,groups[1].Key);
            if(groups[0].Count()==3&&groups[1].Count()==2)return Score(6,groups[0].Key,groups[1].Key);
            if(flush)return Score(5,r);
            if(straight>0)return Score(4,straight);
            if(groups[0].Count()==3)return Score(3,groups[0].Key,groups[1].Key,groups[2].Key);
            if(groups[0].Count()==2&&groups[1].Count()==2)return Score(2,groups[0].Key,groups[1].Key,groups[2].Key);
            if(groups[0].Count()==2)return Score(1,groups[0].Key,groups[1].Key,groups[2].Key,groups[3].Key);
            return Score(0,r);
        }
    }
}
