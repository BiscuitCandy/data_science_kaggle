import os
import re
import pandas as pd
from operator import itemgetter
def extract_sql_info(directory):
	results=[]
	t2 = pd.DataFrame(results)
	data = []
	cnt=0
	for root, dirs, files in os.walk(directory):
		for file in files:
			if file.endswith('.sas'):
				file_path = os.path.join(root, file)
				with open(file_path,'r') as f:
					content = f.read()
				#extract sql 
				sql_blocks = re.findall(r'proc\s+sql.*?quit;', content, re.IGNORECASE | re.DOTALL)
				ignore_words = ['DISTINCT','UNIQUE',' ','','2', 'SUM','.',' .','UPCASE','UCASE','SUBSTR','INTCK','COMPRESS','CASE','MISSING','NOT','MAX','MIN']
				temp_res = []
				for block in sql_blocks:
                                    data_source=[]
                                    tables_final=[]
                                    columns_final=[]
                                    #extract tables Databases
                                    tables = re.findall(r'\bfrom\s+(\w+.\w+)', block, re.IGNORECASE)
                                    for table in tables:
                                        
                                        if '.' in table:
                                            x,y = table.split('.')
                                            t=[]
                                            t.append(y.upper())
                                            if x not in data_source:
                                                    
                                                x=x.upper()
                                                data_source.append(x)
                                            if y not in tables_final:
                                                y=y.upper()
                                                tables_final.append(y)
                                            jointables = re.findall(r'join\s+(\w+.\w+)', block, re.IGNORECASE)
                                            for table1 in jointables:
                                                    if '.' in table1:
                                                            x10,y10 = table1.split('.')
                                                            if y10 not in tables_final:
                                                                    y10=y10.upper()
                                                                    tables_final.append(y10)
                                                                    if y10:
                                                                            t.append(y10.upper())
                                                            if x10 not in data_source:
                                                                    x10=x10.upper()
                                                                    data_source.append(x10)
                                            c1 = re.findall(r'select\s+([\w.]+)',block,re.IGNORECASE)
                                            c2 = re.findall(r',\s*([\w.]+)',block,re.IGNORECASE)
                                            columns = c1+c2
                                            w1 = re.findall(r'where\s+([\w.]+)',block,re.IGNORECASE)
                                            w2 = re.findall(r'AND\s*([\w.]+)',block,re.IGNORECASE)
                                            wherecolumns = w1+w2
                                            j1 = re.findall(r'on\s+([\w.]+)',block,re.IGNORECASE)
                                            tempintvalues=[]
                                            if columns:
                                                if '.' in columns[0]:
                                                    for col in columns:
                                                        if '.' in col:
                                                            x1,y1 = col.split('.')
                                                            y1 = y1.upper()
                                                            if y1 not in columns_final:
                                                                columns_final.append(y1)
                                                else:
                                                    for i in columns:
                                                        i=i.upper()
                                                        if i not in columns_final:
                                                                try:
                                                                        tempintvalues.append(int(i))
                                                                except ValueError:
                                                                        columns_final.append(i)
                                        
                                            if wherecolumns:
                                                for c1 in wherecolumns:
                                                    if '.' in c1:
                                                        x2,y2 = c1.split('.')
                                                        y2=y2.upper()
                                                        if y2 not in columns_final:
                                                            columns_final.append(y2)
                                                    else:
                                                        if c1 not in columns_final:
                                                            c1 = c1.upper()
                                                            columns_final.append(c1)
                                            for k in ignore_words:
                                                if k in columns_final:
                                                    columns_final.remove(k)
                                            if j1:
                                                for j in j1:
                                                    if '.' in j:
                                                        x3,y3 = j.split('.')
                                                        y3 = y3.upper()
                                                        if y3 not in columns_final:
                                                            columns_final.append(y3)
                                            ticket =0
                                            data_source = list(set(data_source))
                                            if temp_res:
                                                    for r in range(0,len(temp_res)):
                                                            if y in temp_res[r]['table']:
                                                                    ticket = 1
                                                                    temp_store = temp_res[r]['columns']+columns_final
                                                                    tempt = list(set(temp_store))
                                                                    temp_res[r]['columns']= sorted(tempt)
                                                    if ticket==0:
                                                            temp_res.append({'program':file_path[35:],'Data Source':data_source, 'table':t, 'columns':sorted(list(set(columns_final)))})
        
                                            else:
                                                    temp_res.append({'program':file_path[35:],'Data Source':data_source, 'table':t, 'columns':sorted(list(set(columns_final)))})
				temp_res = sorted(temp_res,key = itemgetter('Data Source', 'table'))
				results = results+temp_res
	for result in results:
                data.append({'program':result['program'],'Data Source':','.join(result['Data Source']), 'table':','.join(result['table']), 'columns': ','.join(sorted(result['columns']))})
	df = pd.DataFrame(data)
	df = df.drop_duplicates()
	return df			
directory = r'C:\Users\G62085\Documents\sets1-8\set8'
result_df = extract_sql_info(directory)
result_df.to_csv('set8.csv',index = False)

print(f"Processes {len(result_df)} reports.")
print("results Saved")

