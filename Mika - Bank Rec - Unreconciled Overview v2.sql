--Mika - Bank Rec - Unreconciled Overview v2
--Created:  HN - 2023.01.09
--Modified:  2023.01.25

select 
	bg.BankGroupIndex
	, ba.BankAcctIndex
	, b.Name Bank
	, ba.Name  Account_Name
	, ba.AcctNum Account_Number
	, gl.MaskedAlias Cash_GL_Account
	, ba.Currency
	, ba.BankAcctStatusList
	, bg.Name BankGroup
	, mxb.StmtIndex Current_StmtIndex
	, mxb.StmtDate  Current_Bank_StmtDate
	, brec.LastBankRec_Closed_Date
	, cj2.CJ_Unrec_Before20230101_Count
	, cj2.CJ_Unrec_Before20230101_Amount
	, cj2.CJ_Unrec_Before20230101_ABSAmount
	, cj2.CJ_Oldest_GLDate
	, cj2.CJ_Oldest_Trandate
	, bnk.Bank_Unrec_Amount
	, bnk.Bank_Unrec_Line
	, bnk.Bank_Oldest_Unrec_StmntDate
	, bnk.Bank_Oldest_Unrec_ClearDate
from BankGroup bg 
	inner join BankAcct ba on (ba.BankGroup=bg.BankGroupIndex)
	inner join GLAcct gl on (ba.CashGLAcct=gl.AcctIndex)
	inner join Bank b on (ba.Bank=b.BankIndex)
	left outer join (
			select bs.bankgroup 
				,max(bs.StmtIndex)StmtIndex
				, max(bs.StmtDate) StmtDate
			from BankStmt bs
			group by bs.bankgroup
					) mxb on mxb.BankGroup=bg.BankGroupIndex
	left outer join (
			select cs.BankAcct
				, sum(case when cj.GLDate <'1/1/2023'  then 1 else 0 end) CJ_Unrec_Before20230101_Count
				, sum(case when cj.GLDate <'1/1/2023' then abs(cj.Amount) else 0 end) CJ_Unrec_Before20230101_ABSAmount
				, sum(case when cj.GLDate <'1/1/2023' then cj.Amount else 0 end) CJ_Unrec_Before20230101_Amount
				, min (cj.gldate) CJ_Oldest_GLDate
				, min(cj.TranDate) CJ_Oldest_Trandate 
			from CashJournal cj
				inner join cashsource cs on (cj.CashIndex=cs.CashJournal)
				--inner join BankRecWorkDet brcd on  (brcd.CashJournal=cj.CashIndex)
				--inner join BankRecWorkHdr brch on (brcd.BankRecWorkHdr=brch.BankRecWorkHdrID )
			where 1=1
				--and cs.bankacct=2
				and cj.ReconStatusList='O'
				--and cj.TranDate='4/12/2006'
			group by cs.BankAcct
					) cj2 on cj2.BankAcct=ba.BankAcctIndex
	left outer join (
			select bs.bankgroup 
				, sum(bsd.Amount) Bank_Unrec_Amount
				, count(*) Bank_Unrec_Line
				, min(bs.StmtDate)Bank_Oldest_Unrec_StmntDate
				, min(bsd.ClearDate) Bank_Oldest_Unrec_ClearDate
			from BankStmt bs
				inner join BankStmtDetail bsd on (bsd.BankStmt=bs.StmtIndex)
			where 1=1
				and isnull(bsd.ReconStatusList,'O')='O'
			group by bs.bankgroup
					) bnk on bnk.BankGroup=bg.BankGroupIndex
	left outer join (
			select h.BankGroup
				, max( h.ReconcileDate) LastBankRec_Closed_Date
			from BankRecWorkHdr h
			where h.IsReconciled=1
			group by h.BankGroup
					) brec on (brec.BankGroup=bg.BankGroupIndex)
where 1=1
	--and ba.BankAcctStatusList='O'
order by BankAcctIndex, BankGroupIndex

---

