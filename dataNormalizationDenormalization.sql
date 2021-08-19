DROP TABLE gradeCategory
CREATE TABLE gradeCategory(
catId int identity
CONSTRAINT PK_gradeId PRIMARY KEY(catId),
gradeLable char(5),
minAvg int, 
maxAvg int,
minTotalPoints int,
maxTotalPoints int)

DROP TABLE examRecordTab
CREATE TABLE examRecordTab (
studentGradeId int identity
CONSTRAINT PK_studentGradId PRIMARY KEY(studentGradeId),
midTermExam int,
finalExam int, 
assignment1 int,
assignment2 int,
studentGrade_Id int
CONSTRAINT FK_studentGradeId FOREIGN KEY(studentGrade_Id) REFERENCES gradeCategory(catId))

DROP TABLE studentTab
CREATE TABLE studentTab(
studentIdentification int identity
CONSTRAINT PK_studentIdentification PRIMARY KEY(studentIdentification),
firstName varchar(40),
lastName varchar(40),
studentRecordId int,
CONSTRAINT FK_studentRecordId FOREIGN KEY(studentRecordId) REFERENCES examRecordTab(studentGradeId))

/*insert into examRecordTab*/
INSERT INTO examRecordTab(midTermExam, finalExam, assignment1, assignment2)
SELECT midTerm_Exam, final_Exam, assignment_1, assignment_1 
FROM gradeRecordModuleV
WHERE studentID is not null

SELECT * FROM examRecordTab

/*insert into studentTab*/
INSERT INTO studentTab(firstName, lastName)
SELECT DISTINCT first_name, Lastname FROM gradeRecordModuleV

SELECT * FROM studentTab;

/*insert into gradeCategory*/
INSERT INTO gradeCategory
SELECT DISTINCT grade, MIN(studentAvg) minStudentAvg, MAX(studentAvg) maxStudentAvg, MIN(Totalpoints) minTotalpoints, MAX(Totalpoints) maxTotalpoints
FROM [dbo].[gradeRecordModuleV]
GROUP BY grade
ORDER BY grade ASC

SELECT * FROM gradeCategory

/*updating table from the from another table*/
UPDATE studentTab
SET studentTab.studentRecordId = gradeRecordModuleV.uniqueId 
FROM gradeRecordModuleV 
JOIN studentTab
ON studentTab.firstName = gradeRecordModuleV.First_name
AND studentTab.lastName = gradeRecordModuleV.Lastname


UPDATE gradeRecordModuleV
SET keyRef = catId FROM gradeRecordModuleV
JOIN gradeCategory ON 
gradeCategory.maxTotalPoints = gradeRecordModuleV.totalpoints
OR gradeCategory.minTotalPoints = gradeRecordModuleV.totalpoints
OR 
gradeCategory.gradeLable = gradeRecordModuleV.Grade
 
UPDATE examRecordTab
SET studentGrade_Id = keyRef FROM examRecordTab
JOIN gradeRecordModuleV ON 
examRecordTab.midTermExam = gradeRecordModuleV.midTerm_Exam
OR examRecordTab.finalExam = gradeRecordModuleV.final_Exam
OR examRecordTab.assignment1 = gradeRecordModuleV.assignment_1

UPDATE studentTab
SET oldStudentId = studentID
FROM studentTab
JOIN gradeRecordModuleV ON 
studentTab.firstName = First_name
AND studentTab.lastName = gradeRecordModuleV.Lastname

/*prepar data for normalization*/

SELECT TOP 5 * FROM [dbo].[gradeRecordModuleV_Orginal]

 SELECT DISTINCT MIN(midTerm_Exam) minMidTerm, MIN(final_Exam) minFinal, MIN(assignment_1) minAssg1, MIN(assignment_2) minAssg2,
 MAX(midTerm_Exam) maxMidTerm, MAX(final_Exam) maxFinalExam, MAX(assignment_1) maxAssg1, MAX(assignment_2) maxAssg2, grade,
 MIN(studentAvg) minStudentAvg, MAX(studentAvg) maxStudentAvg, MIN(Totalpoints) minTotalpoints, MAX(Totalpoints) maxTotalpoints,  COUNT(*) countAll
 FROM [dbo].[gradeRecordModuleV]
 GROUP BY grade
 ORDER BY grade ASC  
 
  
  /*Find duplicate rows*/
  
WITH cte AS 
(
SELECT *, ROW_NUMBER() OVER 
(
 PARTITION BY studentid ORDER BY studentid
) row_no
 FROM gradeRecordModuleV_Orginal
)
SELECT * FROM cte WHERE row_no >1
  
SELECT * FROM [dbo].[gradeRecordModuleV_Orginal]
WHERE studentid in (35932, 47058,64698)
ORDER BY studentid


ALTER TABLE gradeRecordModuleV
ADD studentAvg INT

ALTER TABLE gradeRecordModuleV
ADD midTerm_Exam INT

ALTER TABLE gradeRecordModuleV
ADD final_Exam INT

ALTER TABLE gradeRecordModuleV
ADD assignment_1 INT

ALTER TABLE gradeRecordModuleV
ADD assignment_2 INT
  
ALTER TABLE studentTab
ADD oldStudentId INT

/*adding uniqueId field to the base table*/

ALTER TABLE [dbo].[gradeRecordModuleV]
ADD uniqueId INT IDENTITY

  /*updating columns*/  
 
WITH cte AS 
(
SELECT studentid, row_number() OVER 
(
 PARTITION BY studentid ORDERY BY studentid
) row_no
 FROM gradeRecordModuleV
)
UPDATE gradeRecordModuleV
SET midTerm_Exam = Midtermexam*100

UPDATE gradeRecordModuleV
SET final_Exam = finalexam*100

UPDATE gradeRecordModuleV
SET assignment_1 = assignment1*100

UPDATE gradeRecordModuleV
SET assignment_2 = assignment2*100

UPDATE gradeRecordModuleV
SET studentAvg = Studentaverage*100
WHERE studentAvg <> null

SELECT * FROM gradeRecordModuleV

/*CREATE DB OBJECTS*/
ALTER TABLE studentTab
DROP CONSTRAINT FK_studentRecordId

ALTER TABLE examRecordTab
DROP CONSTRAINT FK_studentGradeId

/*Aggreagte data */

 SELECT DISTINCT MIN(midTerm_Exam) minMidTerm, MIN(final_Exam) minFinal, MIN(assignment_1) minAssg1, MIN(assignment_2) minAssg2,
 MAX(midTerm_Exam) maxMidTerm, MAX(final_Exam) maxFinalExam, MAX(assignment_1) maxAssg1, MAX(assignment_2) maxAssg2, grade,
 MIN(studentAvg) minStudentAvg, MAX(studentAvg) maxStudentAvg, MIN(Totalpoints) minTotalpoints, MAX(Totalpoints) maxTotalpoints,  COUNT(*) countAll
 FROM [dbo].[gradeRecordModuleV]
 GROUP BY grade
 ORDER BY grade ASC
 
 /*Data denormilization*/

SELECT s.oldStudentId, s.firstName, s.lastName, (e.midTermExam)*0.01 midTermExam, (e.finalExam)*0.01 finalExam, 
(e.assignment1)*0.01 assignment1, (e.assignment2)*0.01 assignment2, 
midTermExam + finalExam + assignment1 + assignment2 AS totalpoints,
(midTermExam + finalExam + assignment1 + assignment2)/4*0.01 as studentAvg, g.gradeLable
FROM studentTab s, gradeCategory g, examRecordTab e
WHERE g.catId  = e.studentGrade_Id 
AND
e.studentGradeId = s.studentRecordId
ORDER BY oldStudentId