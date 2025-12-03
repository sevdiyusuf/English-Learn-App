#!/usr/bin/env python3
"""
Script to update dictionary.json with common English verbs and adjectives
"""

import json
import os

# Verbs list (provided by user)
VERBS_STR = "ask,be,have,do,say,get,make,go,know,take,see,come,think,look,want,give,use,find,tell,ask,work,seem,feel,try,leave,call,need,become,put,mean,keep,let,begin,seem,help,talk,turn,start,show,hear,play,run,move,live,believe,bring,happen,write,sit,stand,lose,pay,meet,include,continue,set,learn,change,lead,understand,watch,follow,stop,create,speak,read,allow,spend,add,win,offer,remember,love,consider,appear,buy,wait,serve,die,send,expect,build,stay,fall,cut,reach,kill,remain,suggest,raise,pass,sell,require,report,decide,pull,return,explain,hope,develop,carry,break,receive,agree,support,hit,produce,eat,cover,cause,choose,point,listen,realize,place,accept,feature,avoid,imagine,describe,charge,focus,drop,push,prepare,reduce,open,increase,apply,shake,manage,confirm,protect,finish,miss,fear,afford,improve,attend,depend,reflect,guess,connect,enter,mention,act,indicate,invite,print,check,step,select,save,create,affect,aim,arrive,borrow,complain,complete,contact,deliver,design,divide,encourage,handle,identify,join,mark,measure,notice,prefer,prevent,release,remove,repeat,reply,solve,suit,supply,survive,thank,travel,wonder,achieve,admire,advise,agree,announce,approve,arrange,attach,attract,balance,behave,blame,book,care,celebrate,challenge,clean,collect,compare,compete,concern,confuse,consider,consist,contain,convince,correct,criticize,damage,delay,deny,depend,deserve,develop,discuss,discover,divide,earn,educate,enable,encourage,ensure,entertain,establish,examine,exchange,expand,experience,explore,express,fail,fit,fix,forgive,freeze,generate,guard,hire,identify,import,increase,inform,injure,interrupt,introduce,invite,invest,judge,knock,laugh,lay,limit,locate,marry,match,measure,mention,monitor,name,notice,occupy,organize,owe,pack,paint,park,perform,persuade,plant,point,press,pretend,prevent,print,produce,promise,promote,protect,prove,provide,publish,pull,pursue,reach,react,realize,receive,recognize,recommend,record,refer,reflect,refuse,regret,relax,relieve,remain,remind,repair,repeat,replace,reply,report,request,require,rescue,research,respect,respond,restore,restrict,result,retire,return,review,ring,search,select,serve,settle,share,shout,sign,solve,sort,sound,spell,spoil,spread,state,stretch,stress,study,submit,succeed,suffer,suggest,support,suppose,surround,survive,thank,threaten,tie,train,transport,treat,trust,update,upload,use,value,visit,volunteer,wait,warn,wash,watch,whisper,worry,write,admit,advise,allow,answer,apologize,appear,appoint,arrive,assist,assume,attack,attempt,avoid,bathe,beat,beg,behave,bet,bind,bite,boil,brake,breathe,breed,burst,calculate,carve,cast,challenge,cheat,cheer,choke,cling,clip,coach,coil,combat,command,commit,compel,condemn,confess,confront,confuse,connect,conserve,construct,consult,contain,contribute,convert,convince,cook,copy,correct,cough,count,crack,crash,crawl,creep,criticize,crush,cry,damn,debate,decay,deceive,declare,decorate,defeat,defend,define,delay,delight,deliver,demonstrate,depend,describe,deserve,desire,detect,determine,develop,direct,discard,discipline,discover,discuss,dislike,display,dispose,dissolve,disturb,divide,mark,drag,drill,drop,dump,earn,edit,educate,embarrass,emphasize,employ,enable,enclose,encounter,encourage,end,endorse,endure,enforce,engage,enhance,enjoy,enlarge,enrich,ensure,entitle,escape,estimate,evaluate,exceed,exchange,exclude,expand,expect,experience,experiment,explain,explode,extend,face,fade,fancy,fasten,favor,fax,fetch,finance,fish,fit,fix,flap,flee,flick,float,flow,fold,follow,forbid,forecast,foresee,forgive,form,frame,frighten,fulfill,gain,gather,gaze,glance,glow,govern,grab,grin,grind,guard,hammer,handle,harass,harvest,haunt,heal,heap,heat,help,hesitate,highlight,hint,hire,hug,hunt,identify,ignore,illustrate,imply,impress,improve,incline,increase,induce,influence,inform,inhale,inject,injure,innovate,inspect,inspire,install,instruct,insult,intend,interest,interfere,interrupt,introduce,invade,inventory,investigate,invite,irritate,isolate,jog,joke,judge,justify,kill,kindle,kiss,kneel,knit,knock,label,land,last,latch,launch,lean,learn,lease,lecture,license,light,like,limit,line,load,locate,lock,log,long,look,loosen,maintain,manage,manipulate,manufacture,mark,marry,match,measure,meditate,mention,merge,miss,monitor,motivate,move,multiply,name,navigate,need,negotiate,nod,notice,obey,observe,obtain,occupy,occur,offend,offer,open,operate,oppose,optimize,order,organize,originate,overcome,overlook,owe,pack,paint,park,participate,pass,pat,patrol,pattern,perform,persist,persuade,plant,plead,please,point,polish,possess,post,postpone,pour,practise,praise,pray,preach,precede,prefer,prepare,presume,press,pretend,prevent,print,proceed,process,produce,profess,profit,progress,prohibit,promise,promote,proofread,propose,prosecute,protect,prove,provide,publish,pull,pump,punch,punish,purchase,push,question,quit,race,raise,react,read,realize,reason,receive,recognize,recommend,record,recover,recruit,reduce,refer,reflect,refuse,regret,release,relieve,rely,remain,remark,remember,remind,repair,repeat,replace,reply,report,represent,request,require,rescue,research,resent,reside,resign,resist,resolve,respect,respond,restore,restrict,result,retire,return,review,revise,ring,rob,ruin,rule,satisfy,save,scan,scare,scatter,school,seal,search,secure,select,send,serve,settle,shape,share,shave,shock,shop,shout,sign,sing,ski,slip,smell,smile,smoke,solve,spell,spend,spill,spoil,spread,stamp,stand,start,state,stay,steer,step,stick,stimulate,stir,stop,store,stretch,strike,strip,study,submit,substitute,subtract,succeed,suffer,suggest,suit,supervise,suppose,surprise,surround,survive,suspect,suspend,sweep,swim,switch,tailor,taunt,teach,telephone,tempt,test,thank,threaten,throw,tie,tip,tolerate,top,trace,track,trade,train,transfer,transform,translate,transport,trap,travel,treat,trick,trust,try,tune,type,undergo,understand,undo,unite,unlock,update,upgrade,upset,urge,use,utilize,vanish,visit,volunteer,wait,wake,walk,warn,wash,waste,watch,water,wear,weigh,welcome,whisper,win,wipe,wish,work,worry,worship,wrap,write,yawn,zip"

# Adjectives list (provided by user)
ADJECTIVES_STR = "good,bad,new,old,young,small,large,big,long,short,tall,early,late,great,little,high,low,right,left,public,private,important,different,able,possible,likely,real,sure,only,clear,common,full,whole,strong,weak,free,hot,cold,warm,cool,heavy,light,hard,soft,open,closed,rich,poor,deep,shallow,fast,slow,happy,sad,angry,funny,serious,beautiful,ugly,nice,kind,rude,polite,friendly,smart,stupid,brave,scared,afraid,calm,nervous,tired,wide,narrow,clean,dirty,quiet,loud,silent,bright,dark,fresh,dry,wet,modern,ancient,healthy,sick,boring,exciting,amazing,awful,perfect,terrible,dangerous,safe,cheap,expensive,crazy,fat,thin,huge,tiny,similar,different,available,aware,alive,dead,correct,wrong,fair,unfair,legal,illegal,normal,strange,fun,serious,typical,rare,global,local,major,minor,domestic,foreign,famous,popular,successful,traditional,technical,emotional,political,economic,social,cultural,military,medical,educational,scientific,basic,complex,simple,complicated,practical,theoretical,helpful,useful,useless,creative,active,passive,positive,negative,central,complete,incomplete,final,initial,previous,next,whole,various,numerous,regular,irregular,chief,primary,secondary,extra,additional,common,familiar,specific,general,wide,close,distant,exact,accurate,critical,serious,rare,fresh,dry,special,typical,ancient,modern,urban,rural,domestic,global,pure,empty,busy,quiet,available,unavailable,essential,optional,unknown,familiar,independent,dependent,intelligent,creative,brilliant,gentle,rough,sharp,flat,round,square,triangular,sweet,sour,bitter,salty,spicy,juicy,ripe,raw,cooked,bright,dull,soft,fuzzy,smooth,rough,slippery,sticky,weak,strong,firm,loose,proud,ashamed,guilty,innocent,anxious,curious,eager,relaxed,confused,annoyed,jealous,grateful,hopeful,helpless,careful,careless,skillful,unskilled,lazy,hardworking,ambitious,generous,selfish,loyal,disloyal,honest,dishonest,responsible,irresponsible,patient,impatient,confident,insecure,organized,disorganized,flexible,inflexible,accurate,inaccurate,efficient,inefficient,creative,uncreative,polite,impolite,friendly,unfriendly,brave,cowardly,helpful,unhelpful,comfortable,uncomfortable,fashionable,unfashionable,proud,modest,serious,playful,willing,unwilling,pleasant,unpleasant,strict,lenient,careful,reckless,tidy,messy,sharp,blunt,consistent,inconsistent,visible,invisible,possible,impossible,regular,irregular,explicit,implicit,obvious,subtle,formal,informal,legal,illegal,logical,illogical,famous,infamous,precise,vague,stable,unstable,steady,unsteady,optimistic,pessimistic,realistic,unrealistic,reasonable,unreasonable,acceptable,unacceptable,accurate,inaccurate,genuine,fake,global,local,internal,external,superior,inferior,senior,junior,maximum,minimum,alternative,traditional,ancient,modern,urban,rural,domestic,foreign,ideal,real,classic,trendy,social,political,economic,scientific,medical,military,educational,cultural,technical,practical,theoretical,basic,advanced,elementary,intermediate,complex,simple,complicated,efficient,inefficient,accurate,inaccurate,identical,similar,different,unique,single,double,empty,full,available,unavailable,visible,invisible,obvious,unclear,accurate,precise,rough,smooth,soft,hard,firm,loose,solid,liquid,gas,frozen,boiling,thick,thin,wide,narrow,deep,shallow,straight,curved,flat,round,tall,short,heavy,light,strong,weak,fast,slow,loud,quiet,silent,noisy,bright,dark,colorful,pale,fresh,rotten,new,old,ancient,modern,early,late,final,initial,previous,next,monthly,annual,daily,weekly,constant,temporary,permanent,frequent,rare,usual,unusual,common,uncommon,typical,atypical,regular,irregular,legal,illegal,normal,abnormal,healthy,sick,fit,ill,alive,dead,mental,physical,emotional,spiritual,active,passive,calm,nervous,tired,energetic,hungry,thirsty,fat,thin,slim,obese,beautiful,ugly,cute,pretty,handsome,attractive,unattractive,gorgeous,plain,kind,cruel,helpful,helpless,generous,selfish,loyal,disloyal,honest,dishonest,patient,impatient,confident,insecure,brave,cowardly,creative,boring,funny,serious,friendly,unfriendly,polite,rude,ambitious,lazy,hardworking,organized,disorganized,careful,careless,optimistic,pessimistic,hopeful,hopeless,curious,indifferent,grateful,ungrateful,proud,ashamed,guilty,innocent,smart,stupid,intelligent,ignorant,wise,foolish,experienced,inexperienced,professional,amateur,rich,poor,wealthy,broke,important,unimportant,essential,optional,necessary,unnecessary,correct,wrong,true,false,real,fake,genuine,artificial,major,minor,primary,secondary,central,peripheral,local,global,internal,external,domestic,foreign,national,international,public,private,official,unofficial,formal,informal,legal,illegal,valid,invalid,open,closed,available,busy,quiet,empty,full,wide,narrow,deep,shallow,sharp,blunt,thick,thin,rough,smooth,slippery,sticky,solid,fragile,strong,weak,stable,unstable,balanced,unbalanced,lucky,unlucky,fresh,dry,wet,juicy,ripe,raw,cooked,sweet,sour,bitter,salty,spicy,bland,fatty,healthy,unhealthy,natural,artificial,organic,chemical,modern,ancient,old-fashioned,stylish,fashionable,plain,fancy,expensive,cheap,affordable,luxury,comfortable,uncomfortable,soft,hard,firm,safe,dangerous,secure,insecure,strict,lenient,serious,fun,boring,basic,advanced,elementary,intermediate,complex,simple,creative,logical,illogical,accurate,inaccurate,precise,vague,realistic,unrealistic,reasonable,unreasonable,efficient,inefficient,productive,unproductive,helpful,useless,beneficial,harmful,positive,negative,fair,unfair,kind,mean,brave,scared,warm,cold,hot,cool,tropical,polar,wet,dry,foggy,windy,sunny,cloudy,frozen,boiling,stormy,calm,quiet,noisy"

def parse_word_list(word_str):
    """Parse comma-separated word list and return unique lowercase words"""
    words = [w.strip().lower() for w in word_str.split(',') if w.strip()]
    # Remove duplicates while preserving order
    seen = set()
    unique_words = []
    for word in words:
        if word not in seen:
            seen.add(word)
            unique_words.append(word)
    return unique_words

def main():
    # Parse word lists
    verbs = parse_word_list(VERBS_STR)
    adjectives = parse_word_list(ADJECTIVES_STR)
    
    print(f"Parsed {len(verbs)} unique verbs")
    print(f"Parsed {len(adjectives)} unique adjectives")
    
    # Read existing dictionary
    dict_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'dictionary.json')
    existing_words = {}
    
    if os.path.exists(dict_path):
        with open(dict_path, 'r', encoding='utf-8') as f:
            existing_dict = json.load(f)
            for entry in existing_dict:
                word = entry.get('word', '').lower().strip()
                word_type = entry.get('type', '').lower().strip()
                if word:
                    existing_words[word] = word_type
        print(f"Found {len(existing_words)} existing words in dictionary")
    else:
        print("No existing dictionary found, creating new one")
    
    # Build new dictionary
    new_dict = []
    all_words = set()
    
    # Add verbs first, then adjectives (verbs before adjectives)
    for verb in verbs:
        word = verb.lower().strip()
        if word and word not in all_words:
            new_dict.append({"word": word, "type": "verb"})
            all_words.add(word)
    
    # Add adjectives
    for adjective in adjectives:
        word = adjective.lower().strip()
        if word and word not in all_words:
            new_dict.append({"word": word, "type": "adjective"})
            all_words.add(word)
    
    # Sort: verbs first (type='verb' comes before 'adjective'), then by word alphabetically
    new_dict.sort(key=lambda x: (0 if x['type'] == 'verb' else 1, x['word']))
    
    print(f"\nCreated dictionary with {len(new_dict)} entries:")
    print(f"  - Verbs: {sum(1 for e in new_dict if e['type'] == 'verb')}")
    print(f"  - Adjectives: {sum(1 for e in new_dict if e['type'] == 'adjective')}")
    
    # Write to file
    with open(dict_path, 'w', encoding='utf-8') as f:
        json.dump(new_dict, f, indent=4, ensure_ascii=False)
    
    print(f"\n✓ Dictionary saved to {dict_path}")
    
    # Also update functions dictionary
    functions_dict_path = os.path.join(os.path.dirname(__file__), '..', 'functions', 'src', 'dictionary.json')
    with open(functions_dict_path, 'w', encoding='utf-8') as f:
        json.dump(new_dict, f, indent=4, ensure_ascii=False)
    
    print(f"✓ Functions dictionary saved to {functions_dict_path}")

if __name__ == '__main__':
    main()

