defmodule Ontogen.DiffTest do
  use OntogenCase

  doctest Ontogen.Diff

  alias Ontogen.Diff

  describe "merge_commits/2" do
    test "disjunctive changesets" do
      assert Diff.merge_commits(
               commit(
                 insert: {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 delete: {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 update: {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 replace: {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 overwrite: {EX.s5_1(), EX.p5_1(), EX.o5_1()}
               ),
               commit(
                 insert: {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                 delete: {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                 update: {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                 replace: {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                 overwrite: {EX.s5_2(), EX.p5_2(), EX.o5_2()}
               )
             ) ==
               %Diff{
                 insert:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()}
                   ]),
                 delete:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()}
                   ])
               }
    end

    test "equal changesets" do
      changeset =
        commit(
          insert: {EX.s1(), EX.p1(), EX.o1()},
          delete: {EX.s2(), EX.p2(), EX.o2()},
          update: {EX.s3(), EX.p3(), EX.o3()},
          replace: {EX.s4(), EX.p4(), EX.o4()},
          overwrite: {EX.s5(), EX.p5(), EX.o5()}
        )

      assert Diff.merge_commits(changeset, changeset) ==
               %Diff{
                 insert: RDF.graph({EX.s1(), EX.p1(), EX.o1()}),
                 delete: RDF.graph({EX.s2(), EX.p2(), EX.o2()}),
                 update: RDF.graph({EX.s3(), EX.p3(), EX.o3()}),
                 replace: RDF.graph({EX.s4(), EX.p4(), EX.o4()}),
                 overwrite: RDF.graph({EX.s5(), EX.p5(), EX.o5()})
               }
    end

    test "insert overlap resolution" do
      assert Diff.merge_commits(
               commit(
                 insert: [
                   {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                   {EX.insert_delete_overlap(), EX.p(), EX.o()},
                   {EX.insert_update_overlap(), EX.p(), EX.o()},
                   {EX.insert_replace_overlap(), EX.p(), EX.o()},
                   {EX.insert_overwrite_overlap(), EX.p(), EX.o()}
                 ],
                 delete: [
                   {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                   {EX.s(), EX.delete_insert_overlap(), EX.o()}
                 ],
                 update: [
                   {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                   {EX.s(), EX.p(), EX.update_insert_overlap()}
                 ],
                 replace: [
                   {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                   {EX.replace_insert_overlap(), EX.p(), EX.o()}
                 ],
                 overwrite: [
                   {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                   {EX.s(), EX.p(), EX.overwrite_insert_overlap()}
                 ]
               ),
               commit(
                 insert: [
                   {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                   {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                   {EX.s(), EX.delete_insert_overlap(), EX.o()},
                   {EX.s(), EX.p(), EX.update_insert_overlap()},
                   {EX.replace_insert_overlap(), EX.p(), EX.o()},
                   {EX.s(), EX.p(), EX.overwrite_insert_overlap()}
                 ],
                 delete: [
                   {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                   {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                   {EX.insert_delete_overlap(), EX.p(), EX.o()}
                 ],
                 update: [
                   {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                   {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                   {EX.insert_update_overlap(), EX.p(), EX.o()}
                 ],
                 replace: [
                   {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                   {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                   {EX.insert_replace_overlap(), EX.p(), EX.o()}
                 ],
                 overwrite: [
                   {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                   {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                   {EX.insert_overwrite_overlap(), EX.p(), EX.o()}
                 ]
               )
             ) ==
               %Diff{
                 insert:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                     {EX.s(), EX.delete_insert_overlap(), EX.o()},
                     {EX.s(), EX.p(), EX.overwrite_insert_overlap()}
                   ]),
                 delete:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.insert_delete_overlap(), EX.p(), EX.o()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                     {EX.insert_update_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.p(), EX.update_insert_overlap()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.insert_replace_overlap(), EX.p(), EX.o()},
                     {EX.replace_insert_overlap(), EX.p(), EX.o()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     {EX.insert_overwrite_overlap(), EX.p(), EX.o()}
                   ])
               }
    end

    test "delete overlap resolution" do
      assert Diff.merge_commits(
               commit(
                 insert: [
                   {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                   {EX.insert_delete_overlap(), EX.p(), EX.o()}
                 ],
                 delete: [
                   {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                   {EX.s1(), EX.delete_insert_overlap(), EX.o()},
                   {EX.s3(), EX.delete_update_overlap(), EX.o()},
                   {EX.s4(), EX.delete_replace_overlap(), EX.o()},
                   {EX.s5(), EX.delete_overwrite_overlap(), EX.o()}
                 ],
                 update: [
                   {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                   {EX.s(), EX.p(), EX.update_delete_overlap()}
                 ],
                 replace: [
                   {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                   {EX.replace_delete_overlap(), EX.p(), EX.o()}
                 ],
                 overwrite: [
                   {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                   {EX.s(), EX.p(), EX.overwrite_delete_overlap()}
                 ]
               ),
               commit(
                 insert: [
                   {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                   {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                   {EX.s1(), EX.delete_insert_overlap(), EX.o()}
                 ],
                 delete: [
                   {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                   {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                   {EX.insert_delete_overlap(), EX.p(), EX.o()},
                   {EX.s(), EX.p(), EX.update_delete_overlap()},
                   {EX.replace_delete_overlap(), EX.p(), EX.o()},
                   {EX.s(), EX.p(), EX.overwrite_delete_overlap()}
                 ],
                 update: [
                   {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                   {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                   {EX.s3(), EX.delete_update_overlap(), EX.o()}
                 ],
                 replace: [
                   {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                   {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                   {EX.s4(), EX.delete_replace_overlap(), EX.o()}
                 ],
                 overwrite: [
                   {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                   {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                   {EX.s5(), EX.delete_overwrite_overlap(), EX.o()}
                 ]
               )
             ) ==
               %Diff{
                 insert:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                     {EX.s1(), EX.delete_insert_overlap(), EX.o()}
                   ]),
                 delete:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.insert_delete_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.p(), EX.update_delete_overlap()},
                     {EX.replace_delete_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.p(), EX.overwrite_delete_overlap()},
                     {EX.s5(), EX.delete_overwrite_overlap(), EX.o()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                     {EX.s3(), EX.delete_update_overlap(), EX.o()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.s4(), EX.delete_replace_overlap(), EX.o()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     # It should never that a statements is overwritten which was previously deleted.
                     # To make this explicit we purposefully keep this statement in both sets.
                     {EX.s5(), EX.delete_overwrite_overlap(), EX.o()}
                   ])
               }
    end

    test "update overlap resolution" do
      assert Diff.merge_commits(
               commit(
                 insert: [
                   {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                   {EX.insert_update_overlap(), EX.p(), EX.o()}
                 ],
                 delete: [
                   {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                   {EX.s2(), EX.delete_update_overlap(), EX.o()}
                 ],
                 update: [
                   {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                   {EX.s1(), EX.p1(), EX.update_insert_overlap()},
                   {EX.s2(), EX.p2(), EX.update_delete_overlap()},
                   {EX.s4(), EX.p4(), EX.update_replace_overlap()},
                   {EX.s5(), EX.p5(), EX.update_overwrite_overlap()}
                 ],
                 replace: [
                   {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                   {EX.replace_update_overlap(), EX.p(), EX.o()}
                 ],
                 overwrite: [
                   {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                   {EX.s3(), EX.p3(), EX.overwrite_update_overlap()}
                 ]
               ),
               commit(
                 insert: [
                   {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                   {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                   {EX.s1(), EX.p1(), EX.update_insert_overlap()}
                 ],
                 delete: [
                   {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                   {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                   {EX.s2(), EX.p2(), EX.update_delete_overlap()}
                 ],
                 update: [
                   {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                   {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                   {EX.insert_update_overlap(), EX.p(), EX.o()},
                   {EX.s2(), EX.delete_update_overlap(), EX.o()},
                   {EX.replace_update_overlap(), EX.p(), EX.o()},
                   {EX.s3(), EX.p3(), EX.overwrite_update_overlap()}
                 ],
                 replace: [
                   {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                   {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                   {EX.s4(), EX.p4(), EX.update_replace_overlap()}
                 ],
                 overwrite: [
                   {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                   {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                   {EX.s5(), EX.p5(), EX.update_overwrite_overlap()}
                 ]
               )
             ) ==
               %Diff{
                 insert:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()}
                   ]),
                 delete:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.s2(), EX.p2(), EX.update_delete_overlap()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                     {EX.insert_update_overlap(), EX.p(), EX.o()},
                     {EX.s2(), EX.delete_update_overlap(), EX.o()},
                     {EX.s3(), EX.p3(), EX.overwrite_update_overlap()},
                     {EX.s1(), EX.p1(), EX.update_insert_overlap()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.s4(), EX.p4(), EX.update_replace_overlap()},
                     {EX.replace_update_overlap(), EX.p(), EX.o()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     {EX.s5(), EX.p5(), EX.update_overwrite_overlap()}
                   ])
               }
    end

    test "replace overlap resolution" do
      assert Diff.merge_commits(
               commit(
                 insert: [
                   {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                   {EX.insert_replace_overlap(), EX.p(), EX.o()}
                 ],
                 delete: [
                   {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                   {EX.s(), EX.delete_replace_overlap(), EX.o()}
                 ],
                 update: [
                   {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                   {EX.s(), EX.p(), EX.update_replace_overlap()}
                 ],
                 replace: [
                   {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                   {EX.replace_insert_overlap(), EX.p(), EX.o()},
                   {EX.replace_delete_overlap(), EX.p(), EX.o()},
                   {EX.replace_update_overlap(), EX.p(), EX.o()},
                   {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
                 ],
                 overwrite: [
                   {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                   {EX.s(), EX.p(), EX.overwrite_replace_overlap()}
                 ]
               ),
               commit(
                 insert: [
                   {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                   {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                   {EX.replace_insert_overlap(), EX.p(), EX.o()}
                 ],
                 delete: [
                   {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                   {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                   {EX.replace_delete_overlap(), EX.p(), EX.o()}
                 ],
                 update: [
                   {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                   {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                   {EX.replace_update_overlap(), EX.p(), EX.o()}
                 ],
                 replace: [
                   {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                   {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                   {EX.insert_replace_overlap(), EX.p(), EX.o()},
                   {EX.s(), EX.delete_replace_overlap(), EX.o()},
                   {EX.s(), EX.p(), EX.update_replace_overlap()},
                   {EX.s(), EX.p(), EX.overwrite_replace_overlap()}
                 ],
                 overwrite: [
                   {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                   {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                   {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
                 ]
               )
             ) ==
               %Diff{
                 insert:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()}
                   ]),
                 delete:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.replace_delete_overlap(), EX.p(), EX.o()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.insert_replace_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.delete_replace_overlap(), EX.o()},
                     {EX.s(), EX.p(), EX.update_replace_overlap()},
                     {EX.s(), EX.p(), EX.overwrite_replace_overlap()},
                     {EX.replace_insert_overlap(), EX.p(), EX.o()},
                     {EX.replace_update_overlap(), EX.p(), EX.o()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
                   ])
               }
    end

    test "overwrite overlap resolution" do
      assert Diff.merge_commits(
               commit(
                 insert: [
                   {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                   {EX.insert_overwrite_overlap(), EX.p(), EX.o()}
                 ],
                 delete: [
                   {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                   {EX.s2(), EX.delete_overwrite_overlap(), EX.o()}
                 ],
                 update: [
                   {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                   {EX.s3(), EX.p3(), EX.update_overwrite_overlap()}
                 ],
                 replace: [
                   {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                   {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
                 ],
                 overwrite: [
                   {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                   {EX.s1(), EX.p1(), EX.overwrite_insert_overlap()},
                   {EX.s2(), EX.p2(), EX.overwrite_delete_overlap()},
                   {EX.s3(), EX.p3(), EX.overwrite_update_overlap()},
                   {EX.s4(), EX.p4(), EX.overwrite_replace_overlap()}
                 ]
               ),
               commit(
                 insert: [
                   {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                   {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                   {EX.s1(), EX.p1(), EX.overwrite_insert_overlap()}
                 ],
                 delete: [
                   {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                   {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                   {EX.s2(), EX.p2(), EX.overwrite_delete_overlap()}
                 ],
                 update: [
                   {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                   {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                   {EX.s3(), EX.p3(), EX.overwrite_update_overlap()}
                 ],
                 replace: [
                   {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                   {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                   {EX.s4(), EX.p4(), EX.overwrite_replace_overlap()}
                 ],
                 overwrite: [
                   {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                   {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                   {EX.insert_overwrite_overlap(), EX.p(), EX.o()},
                   {EX.s2(), EX.delete_overwrite_overlap(), EX.o()},
                   {EX.s3(), EX.p3(), EX.update_overwrite_overlap()},
                   {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
                 ]
               )
             ) ==
               %Diff{
                 insert:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                     {EX.s1(), EX.p1(), EX.overwrite_insert_overlap()}
                   ]),
                 delete:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.s2(), EX.p2(), EX.overwrite_delete_overlap()},
                     {EX.s2(), EX.delete_overwrite_overlap(), EX.o()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                     {EX.s3(), EX.p3(), EX.overwrite_update_overlap()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.s4(), EX.p4(), EX.overwrite_replace_overlap()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     {EX.insert_overwrite_overlap(), EX.p(), EX.o()},
                     # It should never that a statements is overwritten which was previously deleted.
                     # To make this explicit we purposefully keep this statement in both sets.
                     {EX.s2(), EX.delete_overwrite_overlap(), EX.o()},
                     {EX.s3(), EX.p3(), EX.update_overwrite_overlap()},
                     {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
                   ])
               }
    end

    test "empty elements in commits" do
      assert Diff.merge_commits(
               commit(insert: {EX.s(), EX.p(), EX.o()}),
               commit(delete: {EX.s(), EX.p(), EX.o()})
             ) ==
               %Diff{
                 insert: RDF.graph(),
                 delete: RDF.graph({EX.s(), EX.p(), EX.o()}),
                 update: RDF.graph(),
                 replace: RDF.graph(),
                 overwrite: RDF.graph()
               }

      assert Diff.merge_commits(
               commit(delete: {EX.s(), EX.p(), EX.o()}),
               commit(insert: {EX.s(), EX.p(), EX.o()})
             ) ==
               %Diff{
                 insert: RDF.graph({EX.s(), EX.p(), EX.o()}),
                 delete: RDF.graph(),
                 update: RDF.graph(),
                 replace: RDF.graph(),
                 overwrite: RDF.graph()
               }
    end
  end

  describe "merge_commits/1" do
    test "one element list" do
      assert Diff.merge_commits([commit(insert: {EX.s(), EX.p(), EX.o()})]) ==
               %Diff{
                 insert: RDF.graph({EX.s(), EX.p(), EX.o()}),
                 delete: RDF.graph(),
                 update: RDF.graph(),
                 replace: RDF.graph(),
                 overwrite: RDF.graph()
               }
    end

    test "two element list" do
      assert Diff.merge_commits([
               commit(insert: {EX.s(), EX.p(), EX.o()}),
               commit(delete: {EX.s(), EX.p(), EX.o()})
             ]) ==
               Diff.merge_commits(
                 commit(insert: {EX.s(), EX.p(), EX.o()}),
                 commit(delete: {EX.s(), EX.p(), EX.o()})
               )
    end

    test "three element list" do
      assert Diff.merge_commits([
               commit(insert: {EX.s(), EX.p(), EX.o()}),
               commit(delete: {EX.s(), EX.p(), EX.o()}),
               commit(insert: {EX.s(), EX.p(), EX.o()})
             ]) ==
               %Diff{
                 insert: RDF.graph({EX.s(), EX.p(), EX.o()}),
                 delete: RDF.graph(),
                 update: RDF.graph(),
                 replace: RDF.graph(),
                 overwrite: RDF.graph()
               }
    end
  end
end
